/* Copyright (c) 2022 Vector Informatik GmbH

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#include <algorithm>
#include <cstring>
#include <future>
#include <iostream>
#include <iterator>
#include <string>
#include <sstream>
#include <thread>
#include <vector>

#include "silkit/SilKit.hpp"
#include "silkit/services/logging/ILogger.hpp"
#include "silkit/services/orchestration/all.hpp"
#include "silkit/services/orchestration/string_utils.hpp"
#include "silkit/services/can/all.hpp"
#include "silkit/services/can/string_utils.hpp"

extern "C" {
    #include "CM_vBUS.h"
    #include "can_msg.h"
}

using namespace std::chrono_literals;

namespace std {
namespace chrono {
std::ostream& operator<<(std::ostream& out, nanoseconds timestamp) {
    auto seconds = std::chrono::duration_cast<std::chrono::duration<double, std::ratio<1, 1>>>(timestamp);
    out << seconds.count() << "s";
    return out;
}
} // namespace chrono
} // namespace std

void FrameTransmitHandler(const SilKit::Services::Can::CanFrameTransmitEvent& ack, SilKit::Services::Logging::ILogger* logger) {
    std::stringstream buffer;
    buffer << ">> " << ack.status << " for CAN frame with timestamp=" << ack.timestamp
           << " and userContext=" << ack.userContext;
    logger->Info(buffer.str());
    std::cout << ">> " << ack.status << " for CAN frame with timestamp=" << ack.timestamp << " and userContext=" << ack.userContext << std::endl;
}

void FrameHandler(const SilKit::Services::Can::CanFrameEvent& frameEvent, SilKit::Services::Logging::ILogger* logger) {
    std::string payload(frameEvent.frame.dataField.begin(), frameEvent.frame.dataField.end());
    std::stringstream buffer;
    for (int i = 0; i < frameEvent.frame.dlc; i++){
        printf("%02x ", frameEvent.frame.dataField[i]);
    }
    printf("\n");
    
    std::cout << ">> CAN frame: canId=" << frameEvent.frame.canId << std::endl;
}

void SendFrame(SilKit::Services::Can::ICanController* controller, SilKit::Services::Logging::ILogger* logger) {
    SilKit::Services::Can::CanFrame canFrame{};
    canFrame.canId = 3;
    canFrame.flags |= static_cast<SilKit::Services::Can::CanFrameFlagMask>(SilKit::Services::Can::CanFrameFlag::Fdf); // FD Format Indicator
    canFrame.flags |= static_cast<SilKit::Services::Can::CanFrameFlagMask>(SilKit::Services::Can::CanFrameFlag::Brs); // Bit Rate Switch (for FD Format only)

    static int msgId = 0;
    const auto currentMessageId = msgId++;

    std::stringstream payloadBuilder;
    payloadBuilder << "CAN " << (currentMessageId % 100);
    auto payloadStr = payloadBuilder.str();

    std::vector<uint8_t> payloadBytes;
    payloadBytes.resize(payloadStr.size());
    std::copy(payloadStr.begin(), payloadStr.end(), payloadBytes.begin());

    canFrame.dataField = payloadBytes;
    canFrame.dlc = static_cast<uint16_t>(canFrame.dataField.size());

    void* const userContext = reinterpret_cast<void*>(static_cast<intptr_t>(currentMessageId));

    controller->SendFrame(std::move(canFrame), userContext);
    std::stringstream buffer;
    buffer << "<< CAN frame sent with userContext=" << userContext;
    logger->Info(buffer.str());
}

/**************************************************************************************************
 * Main Function
 **************************************************************************************************/

int main(int argc, char** argv) {
    try {
        std::string registryUri = "silkit://localhost:8500";

        auto participantConfiguration = SilKit::Config::ParticipantConfigurationFromString("");
        auto sleepTimePerTick = 1000ms;

        std::string readerName = "Reader";
        auto reader = SilKit::CreateParticipant(participantConfiguration, readerName, registryUri);

        auto* reader_logger = reader->GetLogger();
        auto* reader_canController = reader->CreateCanController("CAN1", "CAN1");

        reader_canController->AddFrameTransmitHandler(
            [reader_logger](SilKit::Services::Can::ICanController* /*ctrl*/, const SilKit::Services::Can::CanFrameTransmitEvent& ack) {
                FrameTransmitHandler(ack, reader_logger);
            }
        );
        reader_canController->AddFrameHandler(
            [reader_logger](SilKit::Services::Can::ICanController* /*ctrl*/, const SilKit::Services::Can::CanFrameEvent& frameEvent) { 
                FrameHandler(frameEvent, reader_logger); 
            }
        );

        auto operationMode = SilKit::Services::Orchestration::OperationMode::Autonomous;

        auto* reader_lifecycleService = reader->CreateLifecycleService({operationMode});

        // Observe state changes
        reader_lifecycleService->SetStopHandler([]() { std::cout << "Stop handler called" << std::endl; });
        reader_lifecycleService->SetShutdownHandler([]() { std::cout << "Shutdown handler called" << std::endl; });
        reader_lifecycleService->SetAbortHandler([](auto lastState) { std::cout << "Abort handler called while in state " << lastState << std::endl; });
        std::cout << "Async Mode" << std::endl;
        std::atomic<bool> isStopRequested = {false};
        std::thread reader_thread;

        std::promise<void> reader_promiseObj;
        std::future<void> reader_futureObj = reader_promiseObj.get_future();
        reader_lifecycleService->SetCommunicationReadyHandler(
            [&]() {
                reader_canController->SetBaudRate(10'000, 1'000'000, 2'000'000);
                reader_thread = std::thread{[&]() {
                    reader_futureObj.get();
                    while (reader_lifecycleService->State() == SilKit::Services::Orchestration::ParticipantState::ReadyToRun
                        || reader_lifecycleService->State() == SilKit::Services::Orchestration::ParticipantState::Running) {
                    }
                    if (!isStopRequested) {
                        std::cout << "Press enter to end the process..." << std::endl;
                    }
                }};
                reader_canController->Start();
            }
        );
        reader_lifecycleService->SetStartingHandler([&]() { reader_promiseObj.set_value(); });
        reader_lifecycleService->StartLifecycle();
        std::cout << "Press enter to leave the simulation..." << std::endl;
        std::cin.ignore();

        isStopRequested = true;
        if (reader_lifecycleService->State() == SilKit::Services::Orchestration::ParticipantState::Running
            || reader_lifecycleService->State() == SilKit::Services::Orchestration::ParticipantState::Paused) {
            std::cout << "User requested to stop in state " << reader_lifecycleService->State() << std::endl;
            reader_lifecycleService->Stop("User requested to stop");
        }

        if (reader_thread.joinable()) {
            reader_thread.join();
        }
        std::cout << "The participant has shut down and left the simulation" << std::endl;
    } catch (const SilKit::ConfigurationError& error) {
        std::cerr << "Invalid configuration: " << error.what() << std::endl;
        std::cout << "Press enter to end the process..." << std::endl;
        std::cin.ignore();
        return -2;
    } catch (const std::exception& error) {
        std::cerr << "Something went wrong: " << error.what() << std::endl;
        std::cout << "Press enter to end the process..." << std::endl;
        std::cin.ignore();
        return -3;
    }

    return 0;
}