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

#include <fstream>
#include <random>
#include <future>
#include <locale>
#include <iostream>
#include <iomanip>

#include "silkit/config/IParticipantConfiguration.hpp"
#include "silkit/services/logging/string_utils.hpp"
#include "silkit/vendor/CreateSilKitRegistry.hpp"
#include "silkit/SilKitVersion.hpp"
#include "silkit/SilKit.hpp"

#include "SignalHandler.hpp"
#include "WindowsServiceMain.hpp"
#include "RegistryConfiguration.hpp"

#include "CommandlineParser.hpp"
#include "ParticipantConfiguration.hpp"
#include "Filesystem.hpp"
#include "FileHelpers.hpp"
#include "YamlParser.hpp"
#include "ParticipantConfigurationFromXImpl.hpp"
#include "CreateSilKitRegistryImpl.hpp"

//dashboard
#include "ValidateAndSanitizeConfig.hpp"

namespace {
std::string lowerCase(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return (unsigned char)std::tolower(c); });
    return s;
}

void ConfigureLogging(std::shared_ptr<SilKit::Config::IParticipantConfiguration> configuration, const std::string& logLevel) {
    auto config = std::dynamic_pointer_cast<SilKit::Config::ParticipantConfiguration>(configuration);
    SILKIT_ASSERT(config != nullptr);

    SilKit::Config::Sink newSink{};
    newSink.type = SilKit::Config::Sink::Type::Stdout;
    newSink.level = SilKit::Services::Logging::from_string(logLevel);
    config->logging.sinks.emplace_back(std::move(newSink));
}

void OverrideFromRegistryConfiguration(std::shared_ptr<SilKit::Config::IParticipantConfiguration> configuration,
                                       const SilKitRegistry::Config::V1::RegistryConfiguration& registryConfiguration) {
    auto config = std::dynamic_pointer_cast<SilKit::Config::ParticipantConfiguration>(configuration);
    SILKIT_ASSERT(config != nullptr);

    if (!registryConfiguration.description.empty()) {
        config->description = registryConfiguration.description;
    }

    if (registryConfiguration.listenUri.has_value()) {
        config->middleware.registryUri = registryConfiguration.listenUri.value();
    }

    if (!registryConfiguration.logging.sinks.empty()) {
        config->logging.sinks = registryConfiguration.logging.sinks;
    }

    if (registryConfiguration.enableDomainSockets.has_value()) {
        config->middleware.enableDomainSockets = registryConfiguration.enableDomainSockets.value();
    }

    config->experimental.metrics = registryConfiguration.experimental.metrics;
}

void OverrideRegistryUri(std::shared_ptr<SilKit::Config::IParticipantConfiguration> configuration, const std::string& registryUri) {
    auto config = std::dynamic_pointer_cast<SilKit::Config::ParticipantConfiguration>(configuration);
    SILKIT_ASSERT(config != nullptr);

    config->middleware.registryUri = registryUri;
}

void SanitizeConfiguration(std::shared_ptr<SilKit::Config::IParticipantConfiguration> configuration, const std::string& listenUri) {
    auto originalConfiguration = std::dynamic_pointer_cast<SilKit::Config::ParticipantConfiguration>(configuration);
    SILKIT_ASSERT(originalConfiguration != nullptr);

    // generate a dummy participant name to satisfy the constraints of the sanitization function
    const std::string participantName = originalConfiguration->participantName.empty() ? "SIL Kit Registry" : originalConfiguration->participantName;

    // sanitize the configuration to select the correct listenUri
    auto result = SilKit::Core::ValidateAndSanitizeConfig(configuration, participantName, listenUri);

    // reset the participant name in the resulting configuration
    result.participantConfiguration.participantName = originalConfiguration->participantName;

    *originalConfiguration = result.participantConfiguration;
}

std::string ExtractRegistryUriFromConfiguration(std::shared_ptr<SilKit::Config::IParticipantConfiguration> configuration) {
    auto cfg = std::dynamic_pointer_cast<SilKit::Config::ParticipantConfiguration>(configuration);
    SILKIT_ASSERT(cfg != nullptr);

    return cfg->middleware.registryUri;
}



SilKitRegistry::RegistryInstance StartRegistry(std::shared_ptr<SilKit::Config::IParticipantConfiguration> configuration, std::string listenUri) {
    std::unique_ptr<SilKit::Vendor::Vector::ISilKitRegistry> registry;

    try {
        registry = SilKit::Vendor::Vector::CreateSilKitRegistryImpl(configuration);
    } catch (const std::exception& exception) {
        std::cerr << "error during registry creation: " << exception.what() << std::endl;
        throw;
    } catch (...) {
        std::cerr << "unknown error during registry creation" << std::endl;
        throw;
    }
    const auto chosenListenUri = registry->StartListening(listenUri);
    std::cout << "SIL Kit Registry listening on " << chosenListenUri << std::endl;

    OverrideRegistryUri(configuration, chosenListenUri);

    SilKitRegistry::RegistryInstance result;
    result._registry = std::move(registry);
    return result;
}

} // namespace

int main(int argc, char** argv) {
    std::cout << "Vector SIL Kit -- Registry, SIL Kit version: " << SilKit::Version::String() << std::endl << std::endl;
    std::string listenUri = "silkit://localhost:8500";
    std::string logLevel = "info";
    try {
        SilKitRegistry::Config::V1::RegistryConfiguration registryConfiguration{};
        auto configuration = SilKit::Config::ParticipantConfigurationFromStringImpl("");
        ConfigureLogging(configuration, logLevel);
        OverrideFromRegistryConfiguration(configuration, registryConfiguration);
        SanitizeConfiguration(configuration, listenUri);
        std::string listenUri = ExtractRegistryUriFromConfiguration(configuration);
        const auto registry = StartRegistry(configuration, listenUri);

        std::cout << "Press enter to shutdown registry..." << std::endl;
        std::cin.ignore();
    } catch (const SilKit::ConfigurationError& error) {
        std::cerr << "Error in configuration: " << error.what() << std::endl;
        std::cout << "Press enter to stop the process..." << std::endl;
        std::cin.ignore();

        return -2;
    } catch (const std::exception& error) {
        std::cerr << "Something went wrong: " << error.what() << std::endl;
        std::cout << "Press enter to stop the process..." << std::endl;
        std::cin.ignore();

        return -3;
    }

    return 0;
}
