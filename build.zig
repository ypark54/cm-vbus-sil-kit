const std: type = @import("std");
const builtin: type = @import("builtin");
const Dir: type = std.fs.Dir;
const Walker: type = std.fs.Dir.Walker;
const ResolvedTarget: type = std.Build.ResolvedTarget;
const OptimizeMode: type = std.builtin.OptimizeMode;
const InstallArtifact: type = std.Build.Step.InstallArtifact;
const InstallFile: type = std.Build.Step.InstallFile;
const Run: type = std.Build.Step.Run;
const Compile: type = std.Build.Step.Compile;
const Query: type = std.Target.Query;
const Tag: type = std.Target.Os.Tag;
const Step: type = std.Build.Step;
const LazyPath: type = std.Build.LazyPath;

fn addFlags(f: *std.ArrayListAligned([]const u8, null)) !void {
    try f.append("-fvisibility=hidden");
    //try f.append("-fno-keep-inline-dllexport");
    try f.append("-D EXPORT_SilKitAPI");
    try f.append("-pedantic");
    try addWarningFlags(f);
}
fn addWarningFlags(f: *std.ArrayListAligned([]const u8, null)) !void {
    try f.append("-Wa,-mbig-obj");
    try f.append("-Wall");
    try f.append("-Wextra");
    try f.append("-Wcast-align");
    try f.append("-Wpacked");
    try f.append("-Wno-implicit-fallthrough");
    try f.append("-Wno-shadow");
    try f.append("-Wno-format");
    try f.append("-Wno-unused-parameter");
    try f.append("-Wstrict-overflow=1");
    try f.append("-Wno-dangling-reference");
}

fn addIncludePath_SilKit(b: *std.Build, c: *Compile) void {
    c.addIncludePath(b.path("SilKit/include"));
    c.addIncludePath(b.path("SilKit/source"));
    c.addIncludePath(b.path("SilKit/source/config"));
    c.addIncludePath(b.path("SilKit/source/core"));
    c.addIncludePath(b.path("SilKit/source/core/internal"));
    c.addIncludePath(b.path("SilKit/source/core/participant"));
    c.addIncludePath(b.path("SilKit/source/core/requests"));
    c.addIncludePath(b.path("SilKit/source/core/requests/procs"));
    c.addIncludePath(b.path("SilKit/source/core/service"));
    c.addIncludePath(b.path("SilKit/source/core/vasio"));
    c.addIncludePath(b.path("SilKit/source/core/vasio/io"));
    c.addIncludePath(b.path("SilKit/source/experimental"));
    c.addIncludePath(b.path("SilKit/source/experimental/netsim"));
    c.addIncludePath(b.path("SilKit/source/experimental/netsim/SilKitInterface"));
    c.addIncludePath(b.path("SilKit/source/extensions"));
    c.addIncludePath(b.path("SilKit/source/extensions/SilKitExtensionApi"));
    c.addIncludePath(b.path("SilKit/source/extensions/SilKitExtensionImpl"));
    c.addIncludePath(b.path("SilKit/source/dashboard"));
    c.addIncludePath(b.path("SilKit/source/dashboard/Client"));
    c.addIncludePath(b.path("SilKit/source/dashboard/Dto"));
    c.addIncludePath(b.path("SilKit/source/dashboard/IntegrationTests"));
    c.addIncludePath(b.path("SilKit/source/dashboard/Service"));
    c.addIncludePath(b.path("SilKit/source/services/can"));
    c.addIncludePath(b.path("SilKit/source/services/ethernet"));
    c.addIncludePath(b.path("SilKit/source/services/flexray"));
    c.addIncludePath(b.path("SilKit/source/services/lin"));
    c.addIncludePath(b.path("SilKit/source/services/logging"));
    c.addIncludePath(b.path("SilKit/source/services/metrics"));
    c.addIncludePath(b.path("SilKit/source/services/orchestration"));
    c.addIncludePath(b.path("SilKit/source/services/pubsub"));
    c.addIncludePath(b.path("SilKit/source/services/rpc"));
    c.addIncludePath(b.path("SilKit/source/tracing"));
    c.addIncludePath(b.path("SilKit/source/tracing/mock"));
    c.addIncludePath(b.path("SilKit/source/util"));
    c.addIncludePath(b.path("SilKit/source/wire/can"));
    c.addIncludePath(b.path("SilKit/source/wire/ethernet"));
    c.addIncludePath(b.path("SilKit/source/wire/flexray"));
    c.addIncludePath(b.path("SilKit/source/wire/lin"));
    c.addIncludePath(b.path("SilKit/source/wire/pubsub"));
    c.addIncludePath(b.path("SilKit/source/wire/rpc"));
    c.addIncludePath(b.path("SilKit/source/wire/util"));
}

fn addIncludePath_ThirdParty(b: *std.Build, c: *Compile) void {
    c.addIncludePath(b.path("ThirdParty/asio/asio/include"));
    c.addIncludePath(b.path("ThirdParty/fmt/include"));
    c.addIncludePath(b.path("ThirdParty/oatpp/src"));
    c.addIncludePath(b.path("ThirdParty/spdlog/include"));
    c.addIncludePath(b.path("ThirdParty/yaml-cpp/include"));
}
pub fn build(b: *std.Build) !void {
    const target: ResolvedTarget = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .gnu });
    const optimize: OptimizeMode = .ReleaseSafe;

    // libspdlog.a
    const spdlog: *Compile = b.addStaticLibrary(.{
        .name = "spdlog",
        .target = target,
        .optimize = optimize,
    });
    spdlog.addIncludePath(b.path("ThirdParty/fmt/include"));
    spdlog.addIncludePath(b.path("ThirdParty/spdlog/include"));
    var spdlog_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try spdlog_files.append("ThirdParty/spdlog/src/async.cpp");
    try spdlog_files.append("ThirdParty/spdlog/src/cfg.cpp");
    try spdlog_files.append("ThirdParty/spdlog/src/color_sinks.cpp");
    try spdlog_files.append("ThirdParty/spdlog/src/file_sinks.cpp");
    try spdlog_files.append("ThirdParty/spdlog/src/spdlog.cpp");
    try spdlog_files.append("ThirdParty/spdlog/src/stdout_sinks.cpp");
    var spdlog_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try spdlog_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try spdlog_flags.append("-DFMT_HEADER_ONLY=1");
    try spdlog_flags.append("-DSPDLOG_COMPILED_LIB");
    try spdlog_flags.append("-DSPDLOG_FMT_EXTERNAL");
    try spdlog_flags.append("-DUNIT_TEST");
    try spdlog_flags.append("-DNDEBUG");
    try spdlog_flags.append("-std=c++11");
    try spdlog_flags.append("-fvisibility=hidden");
    //try spdlog_flags.append("-fno-keep-inline-dllexport");
    try spdlog_flags.append("-Wa,-mbig-obj");
    spdlog.addCSourceFiles(.{
        .files = spdlog_files.items,
        .flags = spdlog_flags.items,
    });
    spdlog.linkLibCpp();
    b.installArtifact(spdlog);

    //liboatpp.a Dependancies
    const oatpp: *Compile = b.addStaticLibrary(.{
        .name = "oatpp",
        .target = target,
        .optimize = optimize,
    });
    oatpp.addIncludePath(b.path("ThirdParty/oatpp/src"));
    var oatpp_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/algorithm/CRC.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/Coroutine.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/CoroutineWaitList.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/Error.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/Executor.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/Lock.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/Processor.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/worker/IOEventWorker_common.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/worker/IOEventWorker_epoll.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/worker/IOEventWorker_kqueue.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/worker/IOEventWorker_stub.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/worker/IOWorker.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/worker/TimerWorker.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/async/worker/Worker.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/base/CommandLineArguments.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/base/Countable.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/base/Environment.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/concurrency/SpinLock.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/concurrency/Thread.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/buffer/FIFOBuffer.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/buffer/IOBuffer.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/buffer/Processor.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/Bundle.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/ObjectMapper.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/type/Any.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/type/Enum.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/type/List.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/type/Object.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/type/PairList.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/type/Primitive.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/type/Type.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/type/UnorderedMap.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/type/UnorderedSet.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/type/Vector.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/mapping/TypeResolver.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/resource/File.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/resource/InMemoryData.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/resource/TemporaryFile.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/share/MemoryLabel.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/share/StringTemplate.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/stream/BufferStream.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/stream/FIFOStream.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/stream/FileStream.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/stream/Stream.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/data/stream/StreamBufferedProxy.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/IODefinitions.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/parser/Caret.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/parser/ParsingError.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/utils/Binary.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/utils/ConversionUtils.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/utils/Random.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/core/utils/String.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/encoding/Base64.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/encoding/Hex.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/encoding/Unicode.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/Address.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/ConnectionPool.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/ConnectionProvider.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/ConnectionProviderSwitch.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/monitor/ConnectionInactivityChecker.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/monitor/ConnectionMaxAgeChecker.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/monitor/ConnectionMonitor.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/Server.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/tcp/client/ConnectionProvider.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/tcp/Connection.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/tcp/server/ConnectionProvider.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/Url.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/virtual_/client/ConnectionProvider.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/virtual_/Interface.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/virtual_/Pipe.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/virtual_/server/ConnectionProvider.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/network/virtual_/Socket.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/orm/DbClient.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/orm/Executor.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/orm/QueryResult.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/orm/SchemaMigration.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/orm/Transaction.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/parser/json/Beautifier.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/parser/json/mapping/Deserializer.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/parser/json/mapping/ObjectMapper.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/parser/json/mapping/Serializer.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/parser/json/Utils.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/client/ApiClient.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/client/HttpRequestExecutor.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/client/RequestExecutor.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/client/RetryPolicy.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/mime/multipart/FileProvider.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/mime/multipart/InMemoryDataProvider.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/mime/multipart/Multipart.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/mime/multipart/Part.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/mime/multipart/PartList.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/mime/multipart/PartReader.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/mime/multipart/Reader.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/mime/multipart/StatefulParser.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/mime/multipart/TemporaryFileProvider.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/CommunicationError.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/encoding/Chunked.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/encoding/ProviderCollection.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/Http.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/incoming/BodyDecoder.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/incoming/Request.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/incoming/RequestHeadersReader.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/incoming/Response.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/incoming/ResponseHeadersReader.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/incoming/SimpleBodyDecoder.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/outgoing/Body.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/outgoing/BufferBody.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/outgoing/MultipartBody.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/outgoing/Request.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/outgoing/Response.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/outgoing/ResponseFactory.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/outgoing/StreamingBody.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/protocol/http/utils/CommunicationUtils.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/server/api/ApiController.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/server/api/Endpoint.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/server/AsyncHttpConnectionHandler.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/server/handler/AuthorizationHandler.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/server/handler/ErrorHandler.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/server/HttpConnectionHandler.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/server/HttpProcessor.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/server/HttpRouter.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/server/interceptor/AllowCorsGlobal.cpp");
    try oatpp_files.append("ThirdParty/oatpp/src/oatpp/web/url/mapping/Pattern.cpp");
    var oatpp_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try oatpp_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try oatpp_flags.append("-DUNIT_TEST");
    try oatpp_flags.append("-DNDEBUG");
    try oatpp_flags.append("-std=c++11");
    try oatpp_flags.append("-fvisibility=hidden");
    //try oatpp_flags.append("-fno-keep-inline-dllexport");
    try oatpp_flags.append("-Wa,-mbig-obj");
    oatpp.addCSourceFiles(.{
        .files = oatpp_files.items,
        .flags = oatpp_flags.items,
    });
    oatpp.linkLibCpp();
    b.installArtifact(oatpp);

    // libyaml-cpp.a
    const yaml_cpp: *Compile = b.addStaticLibrary(.{
        .name = "yaml_cpp",
        .target = target,
        .optimize = optimize,
    });
    yaml_cpp.addIncludePath(b.path("ThirdParty/yaml-cpp/include"));
    yaml_cpp.addIncludePath(b.path("ThirdParty/yaml-cpp/src"));
    var yaml_cpp_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/binary.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/contrib/graphbuilder.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/contrib/graphbuilderadapter.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/convert.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/depthguard.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/directives.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/emit.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/emitfromevents.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/emitter.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/emitterstate.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/emitterutils.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/exceptions.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/exp.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/memory.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/node.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/node_data.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/nodebuilder.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/nodeevents.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/null.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/ostream_wrapper.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/parse.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/parser.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/regex_yaml.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/scanner.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/scanscalar.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/scantag.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/scantoken.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/simplekey.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/singledocparser.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/stream.cpp");
    try yaml_cpp_files.append("ThirdParty/yaml-cpp/src/tag.cpp");
    var yaml_cpp_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try yaml_cpp_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try yaml_cpp_flags.append("-DUNIT_TEST");
    try yaml_cpp_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try yaml_cpp_flags.append("-DNDEBUG");
    try yaml_cpp_flags.append("-std=gnu++11");
    try yaml_cpp_flags.append("-fvisibility=hidden");
    //try yaml_cpp_flags.append("-fno-keep-inline-dllexport");
    try yaml_cpp_flags.append("-Wa,-mbig-obj");
    yaml_cpp.addCSourceFiles(.{
        .files = yaml_cpp_files.items,
        .flags = yaml_cpp_flags.items,
    });
    yaml_cpp.linkLibCpp();
    b.installArtifact(yaml_cpp);

    // libfmt.a
    const fmt: *Compile = b.addStaticLibrary(.{
        .name = "fmt",
        .target = target,
        .optimize = optimize,
    });
    fmt.addIncludePath(b.path("ThirdParty/fmt/include"));
    var fmt_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try fmt_files.append("ThirdParty/fmt/src/format.cc");
    try fmt_files.append("ThirdParty/fmt/src/os.cc");
    var fmt_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try fmt_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try fmt_flags.append("-DUNIT_TEST");
    try fmt_flags.append("-DNDEBUG");
    try fmt_flags.append("-std=gnu++11");
    try fmt_flags.append("-fvisibility=hidden");
    //try fmt_flags.append("-fno-keep-inline-dllexport");
    try fmt_flags.append("-Wa,-mbig-obj");
    fmt.addCSourceFiles(.{
        .files = fmt_files.items,
        .flags = fmt_flags.items,
    });
    fmt.linkLibCpp();
    b.installArtifact(fmt);

    const O_SilKit_Config: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Config",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_Config.addIncludePath(b.path("SilKit/include"));
    O_SilKit_Config.addIncludePath(b.path("SilKit/source/config"));
    O_SilKit_Config.addIncludePath(b.path("SilKit/source/util"));
    O_SilKit_Config.addIncludePath(b.path("ThirdParty/yaml-cpp/include"));
    var O_SilKit_Config_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Config_files.append("SilKit/source/config/Configuration.cpp");
    try O_SilKit_Config_files.append("SilKit/source/config/ParticipantConfiguration.cpp");
    try O_SilKit_Config_files.append("SilKit/source/config/ParticipantConfigurationFromXImpl.cpp");
    try O_SilKit_Config_files.append("SilKit/source/config/Validation.cpp");
    try O_SilKit_Config_files.append("SilKit/source/config/YamlConversion.cpp");
    try O_SilKit_Config_files.append("SilKit/source/config/YamlParser.cpp");
    try O_SilKit_Config_files.append("SilKit/source/config/YamlSchema.cpp");
    try O_SilKit_Config_files.append("SilKit/source/config/YamlValidator.cpp");
    var O_SilKit_Config_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Config_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Config_flags.append("-DUNIT_TEST");
    try O_SilKit_Config_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Config_flags.append("-DNDEBUG");
    try O_SilKit_Config_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Config_flags);
    O_SilKit_Config.addCSourceFiles(.{
        .files = O_SilKit_Config_files.items,
        .flags = O_SilKit_Config_flags.items,
    });
    O_SilKit_Config.linkLibCpp();
    b.installArtifact(O_SilKit_Config);

    const O_SilKit_Core_Participant: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Core_Participant",
        .target = target,
        .optimize = optimize,
        .use_lld = true,
    });
    addIncludePath_SilKit(b, O_SilKit_Core_Participant);
    addIncludePath_ThirdParty(b, O_SilKit_Core_Participant);
    var O_SilKit_Core_Participant_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Core_Participant_files.append("SilKit/source/core/participant/Participant.cpp");
    try O_SilKit_Core_Participant_files.append("SilKit/source/core/participant/CreateParticipantInternal.cpp");
    try O_SilKit_Core_Participant_files.append("SilKit/source/core/participant/CreateParticipantT.cpp");
    try O_SilKit_Core_Participant_files.append("SilKit/source/core/participant/ValidateAndSanitizeConfig.cpp");
    var O_SilKit_Core_Participant_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Core_Participant_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Core_Participant_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Core_Participant_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Core_Participant_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Core_Participant_flags.append("-DUNIT_TEST");
    try O_SilKit_Core_Participant_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Core_Participant_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Core_Participant_flags.append("-DNDEBUG");
    try O_SilKit_Core_Participant_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Core_Participant_flags);
    O_SilKit_Core_Participant.addCSourceFiles(.{
        .files = O_SilKit_Core_Participant_files.items,
        .flags = O_SilKit_Core_Participant_flags.items,
    });
    O_SilKit_Core_Participant.linkLibCpp();
    b.installArtifact(O_SilKit_Core_Participant);

    const O_SilKit_Core_Service: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Core_Service",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Core_Service);
    O_SilKit_Core_Service.addIncludePath(b.path("SilKit/source/tracing"));
    O_SilKit_Core_Service.addIncludePath(b.path("SilKit/source/tracing/mock"));
    O_SilKit_Core_Service.addIncludePath(b.path("SilKit/source/util"));
    O_SilKit_Core_Service.addIncludePath(b.path("SilKit/source/wire/can"));
    O_SilKit_Core_Service.addIncludePath(b.path("SilKit/source/wire/ethernet"));
    O_SilKit_Core_Service.addIncludePath(b.path("SilKit/source/wire/flexray"));
    O_SilKit_Core_Service.addIncludePath(b.path("SilKit/source/wire/lin"));
    O_SilKit_Core_Service.addIncludePath(b.path("SilKit/source/wire/pubsub"));
    O_SilKit_Core_Service.addIncludePath(b.path("SilKit/source/wire/rpc"));
    O_SilKit_Core_Service.addIncludePath(b.path("SilKit/source/wire/util"));
    O_SilKit_Core_Service.addIncludePath(b.path("ThirdParty/asio/asio/include"));
    O_SilKit_Core_Service.addIncludePath(b.path("ThirdParty/fmt/include"));
    O_SilKit_Core_Service.addIncludePath(b.path("ThirdParty/yaml-cpp/include"));
    var O_SilKit_Core_Service_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Core_Service_files.append("Silkit/source/core/service/ServiceDiscovery.cpp");
    try O_SilKit_Core_Service_files.append("Silkit/source/core/service/ServiceSerdes.cpp");
    try O_SilKit_Core_Service_files.append("Silkit/source/core/service/SpecificDiscoveryStore.cpp");
    var O_SilKit_Core_Service_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Core_Service_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Core_Service_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Core_Service_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Core_Service_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Core_Service_flags.append("-DUNIT_TEST");
    try O_SilKit_Core_Service_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Core_Service_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Core_Service_flags.append("-DNDEBUG");
    try O_SilKit_Core_Service_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Core_Service_flags);
    O_SilKit_Core_Service.addCSourceFiles(.{
        .files = O_SilKit_Core_Service_files.items,
        .flags = O_SilKit_Core_Service_flags.items,
    });
    O_SilKit_Core_Service.linkLibCpp();
    b.installArtifact(O_SilKit_Core_Service);

    const O_SilKit_Core_RequestReply: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Core_RequestReply",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Core_RequestReply);
    O_SilKit_Core_RequestReply.addIncludePath(b.path("SilKit/source/tracing"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("SilKit/source/tracing/mock"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("SilKit/source/util"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("SilKit/source/wire/can"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("SilKit/source/wire/ethernet"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("SilKit/source/wire/flexray"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("SilKit/source/wire/lin"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("SilKit/source/wire/pubsub"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("SilKit/source/wire/rpc"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("SilKit/source/wire/util"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("ThirdParty/asio/asio/include"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("ThirdParty/fmt/include"));
    O_SilKit_Core_RequestReply.addIncludePath(b.path("ThirdParty/yaml-cpp/include"));
    var O_SilKit_Core_RequestReply_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Core_RequestReply_files.append("SilKit/source/core/requests/RequestReplyService.cpp");
    try O_SilKit_Core_RequestReply_files.append("SilKit/source/core/requests/RequestReplySerdes.cpp");
    var O_SilKit_Core_RequestReply_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Core_RequestReply_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Core_RequestReply_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Core_RequestReply_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Core_RequestReply_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Core_RequestReply_flags.append("-DUNIT_TEST");
    try O_SilKit_Core_RequestReply_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Core_RequestReply_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Core_RequestReply_flags.append("-DNDEBUG");
    try O_SilKit_Core_RequestReply_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Core_RequestReply_flags);
    O_SilKit_Core_RequestReply.addCSourceFiles(.{
        .files = O_SilKit_Core_RequestReply_files.items,
        .flags = O_SilKit_Core_RequestReply_flags.items,
    });
    O_SilKit_Core_RequestReply.linkLibCpp();
    b.installArtifact(O_SilKit_Core_RequestReply);

    const O_SilKit_Core_RequestReply_ParticipantReplies: *Compile = b.addObject(.{
        .name = "O_SilKit_Core_RequestReply_ParticipantReplies",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Core_RequestReply_ParticipantReplies);
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("SilKit/source/tracing"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("SilKit/source/tracing/mock"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("SilKit/source/util"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("SilKit/source/wire/can"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("SilKit/source/wire/ethernet"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("SilKit/source/wire/flexray"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("SilKit/source/wire/lin"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("SilKit/source/wire/pubsub"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("SilKit/source/wire/rpc"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("SilKit/source/wire/util"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("ThirdParty/asio/asio/include"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("ThirdParty/fmt/include"));
    O_SilKit_Core_RequestReply_ParticipantReplies.addIncludePath(b.path("ThirdParty/yaml-cpp/include"));
    var O_SilKit_Core_RequestReply_ParticipantReplies_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Core_RequestReply_ParticipantReplies_files.append("SilKit/source/core/requests/procs/ParticipantReplies.cpp");
    var O_SilKit_Core_RequestReply_ParticipantReplies_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Core_RequestReply_ParticipantReplies_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Core_RequestReply_ParticipantReplies_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Core_RequestReply_ParticipantReplies_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Core_RequestReply_ParticipantReplies_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Core_RequestReply_ParticipantReplies_flags.append("-DUNIT_TEST");
    try O_SilKit_Core_RequestReply_ParticipantReplies_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Core_RequestReply_ParticipantReplies_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Core_RequestReply_ParticipantReplies_flags.append("-DNDEBUG");
    try O_SilKit_Core_RequestReply_ParticipantReplies_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Core_RequestReply_ParticipantReplies_flags);
    O_SilKit_Core_RequestReply_ParticipantReplies.addCSourceFiles(.{
        .files = O_SilKit_Core_RequestReply_ParticipantReplies_files.items,
        .flags = O_SilKit_Core_RequestReply_ParticipantReplies_flags.items,
    });
    O_SilKit_Core_RequestReply_ParticipantReplies.linkLibCpp();

    const O_SilKit_Core_VAsio: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Core_VAsio",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Core_VAsio);
    O_SilKit_Core_VAsio.addIncludePath(b.path("SilKit/source/tracing"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("SilKit/source/tracing/mock"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("SilKit/source/util"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("SilKit/source/wire/can"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("SilKit/source/wire/ethernet"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("SilKit/source/wire/flexray"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("SilKit/source/wire/lin"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("SilKit/source/wire/pubsub"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("SilKit/source/wire/rpc"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("SilKit/source/wire/util"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("ThirdParty/asio/asio/include"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("ThirdParty/fmt/include"));
    O_SilKit_Core_VAsio.addIncludePath(b.path("ThirdParty/yaml-cpp/include"));
    var O_SilKit_Core_VAsio_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/ConnectKnownParticipants.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/ConnectPeer.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/io/impl/AsioCleanupEndpoint.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/io/impl/AsioFormatEndpoint.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/io/impl/AsioGenericRawByteStream.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/io/impl/AsioIoContext.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/io/impl/AsioTimer.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/io/impl/SetAsioSocketOptions.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/io/MakeAsioIoContext.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/RemoteConnectionManager.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/SerializedMessage.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/TransformAcceptorUris.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/VAsioCapabilities.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/VAsioConnection.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/VAsioPeer.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/VAsioProxyPeer.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/VAsioRegistry.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/VAsioSerdes.cpp");
    try O_SilKit_Core_VAsio_files.append("SilKit/source/core/vasio/VAsioSerdes_Protocol30.cpp");
    var O_SilKit_Core_VAsio_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Core_VAsio_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Core_VAsio_flags.append("-DASIO_STANDALONE");
    try O_SilKit_Core_VAsio_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Core_VAsio_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Core_VAsio_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Core_VAsio_flags.append("-DUNIT_TEST");
    try O_SilKit_Core_VAsio_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Core_VAsio_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Core_VAsio_flags.append("-DNDEBUG");
    try O_SilKit_Core_VAsio_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Core_VAsio_flags);
    O_SilKit_Core_VAsio.addCSourceFiles(.{
        .files = O_SilKit_Core_VAsio_files.items,
        .flags = O_SilKit_Core_VAsio_flags.items,
    });
    O_SilKit_Core_VAsio.linkLibCpp();
    b.installArtifact(O_SilKit_Core_VAsio);

    const O_SilKit_Experimental: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Experimental",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Experimental);
    addIncludePath_ThirdParty(b, O_SilKit_Experimental);
    var O_SilKit_Experimental_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Experimental_files.append("SilKit/source/experimental/participant/ParticipantExtensionsImpl.cpp");
    try O_SilKit_Experimental_files.append("SilKit/source/experimental/services/lin/LinControllerExtensionsImpl.cpp");
    var O_SilKit_Experimental_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Experimental_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Experimental_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Experimental_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Experimental_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Experimental_flags.append("-DUNIT_TEST");
    try O_SilKit_Experimental_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Experimental_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Experimental_flags.append("-DNDEBUG");
    try O_SilKit_Experimental_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Experimental_flags);
    O_SilKit_Experimental.addCSourceFiles(.{
        .files = O_SilKit_Experimental_files.items,
        .flags = O_SilKit_Experimental_flags.items,
    });
    O_SilKit_Experimental.linkLibCpp();
    b.installArtifact(O_SilKit_Experimental);

    const O_SilKit_Extensions: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Extensions",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Extensions);
    addIncludePath_ThirdParty(b, O_SilKit_Extensions);
    var O_SilKit_Extensions_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Extensions_files.append("SilKit/source/extensions/SilKitExtensions.cpp");
    try O_SilKit_Extensions_files.append("SilKit/source/extensions/SilKitExtensionImpl/CreateMdf4Tracing.cpp");
    try O_SilKit_Extensions_files.append("SilKit/source/extensions/detail/LoadExtension_win.cpp");
    var O_SilKit_Extensions_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Extensions_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Extensions_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Extensions_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Extensions_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Extensions_flags.append("-DSILKIT_EXTENSION_OS=\"Windows/Win\"");
    try O_SilKit_Extensions_flags.append("-DUNIT_TEST");
    try O_SilKit_Extensions_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Extensions_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Extensions_flags.append("-DNDEBUG");
    try O_SilKit_Extensions_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Extensions_flags);
    O_SilKit_Extensions.addCSourceFiles(.{
        .files = O_SilKit_Extensions_files.items,
        .flags = O_SilKit_Extensions_flags.items,
    });
    O_SilKit_Extensions.linkLibCpp();
    b.installArtifact(O_SilKit_Extensions);

    const O_SilKit_Experimental_NetworkSimulatorInternals: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Experimental_NetworkSimulatorInternals",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Experimental_NetworkSimulatorInternals);
    addIncludePath_ThirdParty(b, O_SilKit_Experimental_NetworkSimulatorInternals);
    var O_SilKit_Experimental_NetworkSimulatorInternals_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Experimental_NetworkSimulatorInternals_files.append("SilKit/source/experimental/netsim/eventproducers/CanEventProducer.cpp");
    try O_SilKit_Experimental_NetworkSimulatorInternals_files.append("SilKit/source/experimental/netsim/eventproducers/EthernetEventProducer.cpp");
    try O_SilKit_Experimental_NetworkSimulatorInternals_files.append("SilKit/source/experimental/netsim/eventproducers/FlexRayEventProducer.cpp");
    try O_SilKit_Experimental_NetworkSimulatorInternals_files.append("SilKit/source/experimental/netsim/eventproducers/LinEventProducer.cpp");
    try O_SilKit_Experimental_NetworkSimulatorInternals_files.append("SilKit/source/experimental/netsim/NetworkSimulatorInternal.cpp");
    try O_SilKit_Experimental_NetworkSimulatorInternals_files.append("SilKit/source/experimental/netsim/SimulatedNetworkInternal.cpp");
    try O_SilKit_Experimental_NetworkSimulatorInternals_files.append("SilKit/source/experimental/netsim/SimulatedNetworkRouter.cpp");
    var O_SilKit_Experimental_NetworkSimulatorInternals_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Experimental_NetworkSimulatorInternals_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Experimental_NetworkSimulatorInternals_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Experimental_NetworkSimulatorInternals_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Experimental_NetworkSimulatorInternals_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Experimental_NetworkSimulatorInternals_flags.append("-DUNIT_TEST");
    try O_SilKit_Experimental_NetworkSimulatorInternals_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Experimental_NetworkSimulatorInternals_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Experimental_NetworkSimulatorInternals_flags.append("-DNDEBUG");
    try O_SilKit_Experimental_NetworkSimulatorInternals_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Experimental_NetworkSimulatorInternals_flags);
    O_SilKit_Experimental_NetworkSimulatorInternals.addCSourceFiles(.{
        .files = O_SilKit_Experimental_NetworkSimulatorInternals_files.items,
        .flags = O_SilKit_Experimental_NetworkSimulatorInternals_flags.items,
    });
    O_SilKit_Experimental_NetworkSimulatorInternals.linkLibCpp();
    b.installArtifact(O_SilKit_Experimental_NetworkSimulatorInternals);

    const O_SilKit_Services_Can: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Services_Can",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Services_Can);
    addIncludePath_ThirdParty(b, O_SilKit_Services_Can);
    var O_SilKit_Services_Can_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Can_files.append("SilKit/source/services/can/CanController.cpp");
    try O_SilKit_Services_Can_files.append("SilKit/source/services/can/CanDatatypesUtils.cpp");
    try O_SilKit_Services_Can_files.append("SilKit/source/services/can/CanSerdes.cpp");
    try O_SilKit_Services_Can_files.append("SilKit/source/services/can/SimBehavior.cpp");
    try O_SilKit_Services_Can_files.append("SilKit/source/services/can/SimBehaviorDetailed.cpp");
    try O_SilKit_Services_Can_files.append("SilKit/source/services/can/SimBehaviorTrivial.cpp");
    var O_SilKit_Services_Can_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Can_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Services_Can_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Services_Can_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Services_Can_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Services_Can_flags.append("-DUNIT_TEST");
    try O_SilKit_Services_Can_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Services_Can_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Services_Can_flags.append("-DNDEBUG");
    try O_SilKit_Services_Can_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Services_Can_flags);
    O_SilKit_Services_Can.addCSourceFiles(.{
        .files = O_SilKit_Services_Can_files.items,
        .flags = O_SilKit_Services_Can_flags.items,
    });
    O_SilKit_Services_Can.linkLibCpp();
    b.installArtifact(O_SilKit_Services_Can);

    const O_SilKit_Services_Ethernet: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Services_Ethernet",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Services_Ethernet);
    addIncludePath_ThirdParty(b, O_SilKit_Services_Ethernet);
    var O_SilKit_Services_Ethernet_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Ethernet_files.append("SilKit/source/services/ethernet/EthController.cpp");
    try O_SilKit_Services_Ethernet_files.append("SilKit/source/services/ethernet/SimBehavior.cpp");
    try O_SilKit_Services_Ethernet_files.append("SilKit/source/services/ethernet/SimBehaviorDetailed.cpp");
    try O_SilKit_Services_Ethernet_files.append("SilKit/source/services/ethernet/SimBehaviorTrivial.cpp");
    try O_SilKit_Services_Ethernet_files.append("SilKit/source/services/ethernet/EthernetSerdes.cpp");
    var O_SilKit_Services_Ethernet_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Ethernet_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Services_Ethernet_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Services_Ethernet_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Services_Ethernet_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Services_Ethernet_flags.append("-DUNIT_TEST");
    try O_SilKit_Services_Ethernet_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Services_Ethernet_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Services_Ethernet_flags.append("-DNDEBUG");
    try O_SilKit_Services_Ethernet_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Services_Ethernet_flags);
    O_SilKit_Services_Ethernet.addCSourceFiles(.{
        .files = O_SilKit_Services_Ethernet_files.items,
        .flags = O_SilKit_Services_Ethernet_flags.items,
    });
    O_SilKit_Services_Ethernet.linkLibCpp();
    b.installArtifact(O_SilKit_Services_Ethernet);

    const O_SilKit_Services_Flexray: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Services_Flexray",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Services_Flexray);
    addIncludePath_ThirdParty(b, O_SilKit_Services_Flexray);
    var O_SilKit_Services_Flexray_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Flexray_files.append("SilKit/source/services/flexray/FlexrayController.cpp");
    try O_SilKit_Services_Flexray_files.append("SilKit/source/services/flexray/FlexrayDatatypeUtils.cpp");
    try O_SilKit_Services_Flexray_files.append("SilKit/source/services/flexray/Validation.cpp");
    try O_SilKit_Services_Flexray_files.append("SilKit/source/services/flexray/FlexraySerdes.cpp");
    var O_SilKit_Services_Flexray_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Flexray_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Services_Flexray_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Services_Flexray_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Services_Flexray_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Services_Flexray_flags.append("-DUNIT_TEST");
    try O_SilKit_Services_Flexray_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Services_Flexray_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Services_Flexray_flags.append("-DNDEBUG");
    try O_SilKit_Services_Flexray_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Services_Flexray_flags);
    O_SilKit_Services_Flexray.addCSourceFiles(.{
        .files = O_SilKit_Services_Flexray_files.items,
        .flags = O_SilKit_Services_Flexray_flags.items,
    });
    O_SilKit_Services_Flexray.linkLibCpp();
    b.installArtifact(O_SilKit_Services_Flexray);

    const O_SilKit_Services_Lin: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Services_Lin",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Services_Lin);
    addIncludePath_ThirdParty(b, O_SilKit_Services_Lin);
    var O_SilKit_Services_Lin_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Lin_files.append("SilKit/source/services/lin/LinController.cpp");
    try O_SilKit_Services_Lin_files.append("SilKit/source/services/lin/SimBehavior.cpp");
    try O_SilKit_Services_Lin_files.append("SilKit/source/services/lin/SimBehaviorDetailed.cpp");
    try O_SilKit_Services_Lin_files.append("SilKit/source/services/lin/SimBehaviorTrivial.cpp");
    try O_SilKit_Services_Lin_files.append("SilKit/source/services/lin/LinSerdes.cpp");
    var O_SilKit_Services_Lin_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Lin_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Services_Lin_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Services_Lin_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Services_Lin_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Services_Lin_flags.append("-DUNIT_TEST");
    try O_SilKit_Services_Lin_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Services_Lin_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Services_Lin_flags.append("-DNDEBUG");
    try O_SilKit_Services_Lin_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Services_Lin_flags);
    O_SilKit_Services_Lin.addCSourceFiles(.{
        .files = O_SilKit_Services_Lin_files.items,
        .flags = O_SilKit_Services_Lin_flags.items,
    });
    O_SilKit_Services_Lin.linkLibCpp();
    b.installArtifact(O_SilKit_Services_Lin);

    const O_SilKit_Services_Logging: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Services_Logging",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Services_Logging);
    addIncludePath_ThirdParty(b, O_SilKit_Services_Logging);
    var O_SilKit_Services_Logging_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Logging_files.append("SilKit/source/services/logging/LogMsgSender.cpp");
    try O_SilKit_Services_Logging_files.append("SilKit/source/services/logging/LogMsgReceiver.cpp");
    try O_SilKit_Services_Logging_files.append("SilKit/source/services/logging/Logger.cpp");
    try O_SilKit_Services_Logging_files.append("SilKit/source/services/logging/LoggingSerdes.cpp");
    var O_SilKit_Services_Logging_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Logging_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Services_Logging_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Services_Logging_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Services_Logging_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Services_Logging_flags.append("-DSPDLOG_COMPILED_LIB");
    try O_SilKit_Services_Logging_flags.append("-DSPDLOG_FMT_EXTERNAL");
    try O_SilKit_Services_Logging_flags.append("-DUNIT_TEST");
    try O_SilKit_Services_Logging_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Services_Logging_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Services_Logging_flags.append("-DNDEBUG");
    try O_SilKit_Services_Logging_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Services_Logging_flags);
    O_SilKit_Services_Logging.addCSourceFiles(.{
        .files = O_SilKit_Services_Logging_files.items,
        .flags = O_SilKit_Services_Logging_flags.items,
    });
    O_SilKit_Services_Logging.linkLibCpp();
    b.installArtifact(O_SilKit_Services_Logging);

    const O_SilKit_Services_Orchestration: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Services_Orchestration",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Services_Orchestration);
    addIncludePath_ThirdParty(b, O_SilKit_Services_Orchestration);
    var O_SilKit_Services_Orchestration_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/LifecycleManagement.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/LifecycleService.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/LifecycleStates.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/SyncDatatypeUtils.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/SyncSerdes.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/SystemController.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/SystemMonitor.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/SystemStateTracker.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/TimeConfiguration.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/TimeProvider.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/TimeSyncService.cpp");
    try O_SilKit_Services_Orchestration_files.append("Silkit/source/services/orchestration/WatchDog.cpp");
    var O_SilKit_Services_Orchestration_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Orchestration_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Services_Orchestration_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Services_Orchestration_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Services_Orchestration_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Services_Orchestration_flags.append("-DUNIT_TEST");
    try O_SilKit_Services_Orchestration_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Services_Orchestration_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Services_Orchestration_flags.append("-DNDEBUG");
    try O_SilKit_Services_Orchestration_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Services_Orchestration_flags);
    O_SilKit_Services_Orchestration.addCSourceFiles(.{
        .files = O_SilKit_Services_Orchestration_files.items,
        .flags = O_SilKit_Services_Orchestration_flags.items,
    });
    O_SilKit_Services_Orchestration.linkLibCpp();
    b.installArtifact(O_SilKit_Services_Orchestration);

    const O_SilKit_Services_PubSub: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Services_PubSub",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Services_PubSub);
    addIncludePath_ThirdParty(b, O_SilKit_Services_PubSub);
    var O_SilKit_Services_PubSub_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_PubSub_files.append("SilKit/source/services/pubsub/DataMessageDatatypeUtils.cpp");
    try O_SilKit_Services_PubSub_files.append("SilKit/source/services/pubsub/DataPublisher.cpp");
    try O_SilKit_Services_PubSub_files.append("SilKit/source/services/pubsub/DataSubscriber.cpp");
    try O_SilKit_Services_PubSub_files.append("SilKit/source/services/pubsub/DataSubscriberInternal.cpp");
    try O_SilKit_Services_PubSub_files.append("SilKit/source/services/pubsub/DataSerdes.cpp");
    var O_SilKit_Services_PubSub_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_PubSub_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Services_PubSub_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Services_PubSub_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Services_PubSub_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Services_PubSub_flags.append("-DUNIT_TEST");
    try O_SilKit_Services_PubSub_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Services_PubSub_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Services_PubSub_flags.append("-DNDEBUG");
    try O_SilKit_Services_PubSub_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Services_PubSub_flags);
    O_SilKit_Services_PubSub.addCSourceFiles(.{
        .files = O_SilKit_Services_PubSub_files.items,
        .flags = O_SilKit_Services_PubSub_flags.items,
    });
    O_SilKit_Services_PubSub.linkLibCpp();
    b.installArtifact(O_SilKit_Services_PubSub);

    const O_SilKit_Services_Rpc: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Services_Rpc",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Services_Rpc);
    addIncludePath_ThirdParty(b, O_SilKit_Services_Rpc);
    var O_SilKit_Services_Rpc_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Rpc_files.append("SilKit/source/services/rpc/RpcClient.cpp");
    try O_SilKit_Services_Rpc_files.append("SilKit/source/services/rpc/RpcDatatypeUtils.cpp");
    try O_SilKit_Services_Rpc_files.append("SilKit/source/services/rpc/RpcSerdes.cpp");
    try O_SilKit_Services_Rpc_files.append("SilKit/source/services/rpc/RpcServer.cpp");
    try O_SilKit_Services_Rpc_files.append("SilKit/source/services/rpc/RpcServerInternal.cpp");
    var O_SilKit_Services_Rpc_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Rpc_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Services_Rpc_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Services_Rpc_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Services_Rpc_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Services_Rpc_flags.append("-DUNIT_TEST");
    try O_SilKit_Services_Rpc_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Services_Rpc_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Services_Rpc_flags.append("-DNDEBUG");
    try O_SilKit_Services_Rpc_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Services_Rpc_flags);
    O_SilKit_Services_Rpc.addCSourceFiles(.{
        .files = O_SilKit_Services_Rpc_files.items,
        .flags = O_SilKit_Services_Rpc_flags.items,
    });
    O_SilKit_Services_Rpc.linkLibCpp();
    b.installArtifact(O_SilKit_Services_Rpc);

    const O_SilKit_Services_Metrics: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Services_Metrics",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Services_Metrics);
    addIncludePath_ThirdParty(b, O_SilKit_Services_Metrics);
    var O_SilKit_Services_Metrics_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Metrics_files.append("SilKit/source/services/metrics/CreateMetricsSinksFromParticipantConfiguration.cpp");
    try O_SilKit_Services_Metrics_files.append("SilKit/source/services/metrics/MetricsDatatypes.cpp");
    try O_SilKit_Services_Metrics_files.append("SilKit/source/services/metrics/MetricsJsonSink.cpp");
    try O_SilKit_Services_Metrics_files.append("SilKit/source/services/metrics/MetricsManager.cpp");
    try O_SilKit_Services_Metrics_files.append("SilKit/source/services/metrics/MetricsProcessor.cpp");
    try O_SilKit_Services_Metrics_files.append("SilKit/source/services/metrics/MetricsReceiver.cpp");
    try O_SilKit_Services_Metrics_files.append("SilKit/source/services/metrics/MetricsRemoteSink.cpp");
    try O_SilKit_Services_Metrics_files.append("SilKit/source/services/metrics/MetricsSender.cpp");
    try O_SilKit_Services_Metrics_files.append("SilKit/source/services/metrics/MetricsSerdes.cpp");
    try O_SilKit_Services_Metrics_files.append("SilKit/source/services/metrics/MetricsTimerThread.cpp");
    var O_SilKit_Services_Metrics_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Services_Metrics_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Services_Metrics_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Services_Metrics_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Services_Metrics_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Services_Metrics_flags.append("-DUNIT_TEST");
    try O_SilKit_Services_Metrics_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Services_Metrics_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Services_Metrics_flags.append("-DNDEBUG");
    try O_SilKit_Services_Metrics_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Services_Metrics_flags);
    O_SilKit_Services_Metrics.addCSourceFiles(.{
        .files = O_SilKit_Services_Metrics_files.items,
        .flags = O_SilKit_Services_Metrics_flags.items,
    });
    O_SilKit_Services_Metrics.linkLibCpp();
    b.installArtifact(O_SilKit_Services_Metrics);

    const O_SilKit_Tracing: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Tracing",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Tracing);
    addIncludePath_ThirdParty(b, O_SilKit_Tracing);
    var O_SilKit_Tracing_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Tracing_files.append("SilKit/source/tracing/detail/NamedPipeWin.cpp");
    try O_SilKit_Tracing_files.append("SilKit/source/tracing/PcapReader.cpp");
    try O_SilKit_Tracing_files.append("SilKit/source/tracing/PcapReplay.cpp");
    try O_SilKit_Tracing_files.append("SilKit/source/tracing/PcapSink.cpp");
    try O_SilKit_Tracing_files.append("SilKit/source/tracing/ReplayScheduler.cpp");
    try O_SilKit_Tracing_files.append("SilKit/source/tracing/Tracing.cpp");
    var O_SilKit_Tracing_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Tracing_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Tracing_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Tracing_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Tracing_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Tracing_flags.append("-DUNIT_TEST");
    try O_SilKit_Tracing_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Tracing_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Tracing_flags.append("-DNDEBUG");
    try O_SilKit_Tracing_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Tracing_flags);
    O_SilKit_Tracing.addCSourceFiles(.{
        .files = O_SilKit_Tracing_files.items,
        .flags = O_SilKit_Tracing_flags.items,
    });
    O_SilKit_Tracing.linkLibCpp();
    b.installArtifact(O_SilKit_Tracing);

    const O_SilKit_Util: *Compile = b.addObject(.{
        .name = "O_SilKit_Util",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_Util.addIncludePath(b.path("SilKit/include"));
    O_SilKit_Util.addIncludePath(b.path("SilKit/source/util"));
    O_SilKit_Util.addIncludePath(b.path("ThirdParty/asio/asio/include"));
    O_SilKit_Util.addIncludePath(b.path("ThirdParty/fmt/include"));
    var O_SilKit_Util_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_files.append("SilKit/source/util/ExecutionEnvironment.cpp");
    var O_SilKit_Util_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Util_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Util_flags.append("-DUNIT_TEST");
    try O_SilKit_Util_flags.append("-DNDEBUG");
    try O_SilKit_Util_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Util_flags);
    O_SilKit_Util.addCSourceFiles(.{
        .files = O_SilKit_Util_files.items,
        .flags = O_SilKit_Util_flags.items,
    });
    O_SilKit_Util.linkLibCpp();

    const O_SilKit_Util_FileHelpers: *Compile = b.addObject(.{
        .name = "O_SilKit_Util_FileHelpers",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_Util_FileHelpers.addIncludePath(b.path("SilKit/include"));
    O_SilKit_Util_FileHelpers.addIncludePath(b.path("SilKit/source/util"));
    var O_SilKit_Util_FileHelpers_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_FileHelpers_files.append("SilKit/source/util/FileHelpers.cpp");
    var O_SilKit_Util_FileHelpers_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_FileHelpers_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Util_FileHelpers_flags.append("-DUNIT_TEST");
    try O_SilKit_Util_FileHelpers_flags.append("-DNDEBUG");
    try O_SilKit_Util_FileHelpers_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Util_FileHelpers_flags);
    O_SilKit_Util_FileHelpers.addCSourceFiles(.{
        .files = O_SilKit_Util_FileHelpers_files.items,
        .flags = O_SilKit_Util_FileHelpers_flags.items,
    });
    O_SilKit_Util_FileHelpers.linkLibCpp();

    const O_SilKit_Util_StringHelpers: *Compile = b.addObject(.{
        .name = "O_SilKit_Util_StringHelpers",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_Util_StringHelpers.addIncludePath(b.path("SilKit/include"));
    O_SilKit_Util_StringHelpers.addIncludePath(b.path("SilKit/source/util"));
    O_SilKit_Util_StringHelpers.addIncludePath(b.path("ThirdParty/fmt/include"));
    var O_SilKit_Util_StringHelpers_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_StringHelpers_files.append("SilKit/source/util/StringHelpers.cpp");
    var O_SilKit_Util_StringHelpers_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_StringHelpers_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Util_StringHelpers_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Util_StringHelpers_flags.append("-DUNIT_TEST");
    try O_SilKit_Util_StringHelpers_flags.append("-DNDEBUG");
    try O_SilKit_Util_StringHelpers_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Util_StringHelpers_flags);
    O_SilKit_Util_StringHelpers.addCSourceFiles(.{
        .files = O_SilKit_Util_StringHelpers_files.items,
        .flags = O_SilKit_Util_StringHelpers_flags.items,
    });
    O_SilKit_Util_StringHelpers.linkLibCpp();

    const O_SilKit_Util_Filesystem: *Compile = b.addObject(.{
        .name = "O_SilKit_Util_Filesystem",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_Util_Filesystem.addIncludePath(b.path("SilKit/include"));
    O_SilKit_Util_Filesystem.addIncludePath(b.path("SilKit/source/util"));
    var O_SilKit_Util_Filesystem_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_Filesystem_files.append("SilKit/source/util/Filesystem.cpp");
    var O_SilKit_Util_Filesystem_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_Filesystem_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Util_Filesystem_flags.append("-DUNIT_TEST");
    try O_SilKit_Util_Filesystem_flags.append("-DNDEBUG");
    try O_SilKit_Util_Filesystem_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Util_Filesystem_flags);
    O_SilKit_Util_Filesystem.addCSourceFiles(.{
        .files = O_SilKit_Util_Filesystem_files.items,
        .flags = O_SilKit_Util_Filesystem_flags.items,
    });
    O_SilKit_Util_Filesystem.linkLibCpp();

    const O_SilKit_Util_SetThreadName: *Compile = b.addObject(.{
        .name = "O_SilKit_Util_SetThreadName",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_Util_SetThreadName.addIncludePath(b.path("SilKit/include"));
    O_SilKit_Util_SetThreadName.addIncludePath(b.path("SilKit/source/util"));
    var O_SilKit_Util_SetThreadName_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_SetThreadName_files.append("SilKit/source/util/SetThreadName.cpp");
    var O_SilKit_Util_SetThreadName_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_SetThreadName_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Util_SetThreadName_flags.append("-DUNIT_TEST");
    try O_SilKit_Util_SetThreadName_flags.append("-DNDEBUG");
    try O_SilKit_Util_SetThreadName_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Util_SetThreadName_flags);
    O_SilKit_Util_SetThreadName.addCSourceFiles(.{
        .files = O_SilKit_Util_SetThreadName_files.items,
        .flags = O_SilKit_Util_SetThreadName_flags.items,
    });
    O_SilKit_Util_SetThreadName.linkLibCpp();

    const O_SilKit_Util_SignalHandler: *Compile = b.addObject(.{
        .name = "O_SilKit_Util_SignalHandler",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_Util_SignalHandler.addIncludePath(b.path("SilKit/include"));
    O_SilKit_Util_SignalHandler.addIncludePath(b.path("SilKit/source/util"));
    var O_SilKit_Util_SignalHandler_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_SignalHandler_files.append("SilKit/source/util/SignalHandler.cpp");
    var O_SilKit_Util_SignalHandler_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_SignalHandler_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Util_SignalHandler_flags.append("-DUNIT_TEST");
    try O_SilKit_Util_SignalHandler_flags.append("-DNDEBUG");
    try O_SilKit_Util_SignalHandler_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Util_SignalHandler_flags);
    O_SilKit_Util_SignalHandler.addCSourceFiles(.{
        .files = O_SilKit_Util_SignalHandler_files.items,
        .flags = O_SilKit_Util_SignalHandler_flags.items,
    });
    O_SilKit_Util_SignalHandler.linkLibCpp();

    const O_SilKit_Util_Uuid: *Compile = b.addObject(.{
        .name = "O_SilKit_Util_Uuid",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_Util_Uuid.addIncludePath(b.path("SilKit/source/util"));
    var O_SilKit_Util_Uuid_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_Uuid_files.append("SilKit/source/util/Uuid.cpp");
    var O_SilKit_Util_Uuid_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_Uuid_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Util_Uuid_flags.append("-DUNIT_TEST");
    try O_SilKit_Util_Uuid_flags.append("-DNDEBUG");
    try O_SilKit_Util_Uuid_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Util_Uuid_flags);
    O_SilKit_Util_Uuid.addCSourceFiles(.{
        .files = O_SilKit_Util_Uuid_files.items,
        .flags = O_SilKit_Util_Uuid_flags.items,
    });
    O_SilKit_Util_Uuid.linkLibCpp();

    const O_SilKit_Util_Uri: *Compile = b.addObject(.{
        .name = "O_SilKit_Util_Uri",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_Util_Uri.addIncludePath(b.path("SilKit/include"));
    O_SilKit_Util_Uri.addIncludePath(b.path("SilKit/source/util"));
    O_SilKit_Util_Uri.addIncludePath(b.path("ThirdParty/fmt/include"));
    var O_SilKit_Util_Uri_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_Uri_files.append("SilKit/source/util/Uri.cpp");
    var O_SilKit_Util_Uri_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_Uri_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Util_Uri_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Util_Uri_flags.append("-DUNIT_TEST");
    try O_SilKit_Util_Uri_flags.append("-DNDEBUG");
    try O_SilKit_Util_Uri_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Util_Uri_flags);
    O_SilKit_Util_Uri.addCSourceFiles(.{
        .files = O_SilKit_Util_Uri_files.items,
        .flags = O_SilKit_Util_Uri_flags.items,
    });
    O_SilKit_Util_Uri.linkLibCpp();

    const O_SilKit_Util_LabelMatching: *Compile = b.addObject(.{
        .name = "O_SilKit_Util_LabelMatching",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_Util_LabelMatching.addIncludePath(b.path("SilKit/include"));
    O_SilKit_Util_LabelMatching.addIncludePath(b.path("SilKit/source/util"));
    var O_SilKit_Util_LabelMatching_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_LabelMatching_files.append("SilKit/source/util/LabelMatching.cpp");
    var O_SilKit_Util_LabelMatching_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Util_LabelMatching_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Util_LabelMatching_flags.append("-DUNIT_TEST");
    try O_SilKit_Util_LabelMatching_flags.append("-DNDEBUG");
    try O_SilKit_Util_LabelMatching_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Util_LabelMatching_flags);
    O_SilKit_Util_LabelMatching.addCSourceFiles(.{
        .files = O_SilKit_Util_LabelMatching_files.items,
        .flags = O_SilKit_Util_LabelMatching_flags.items,
    });
    O_SilKit_Util_LabelMatching.linkLibCpp();

    const O_SilKit_Capi: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Capi",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Capi);
    addIncludePath_ThirdParty(b, O_SilKit_Capi);
    var O_SilKit_Capi_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiCan.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiDataPubSub.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiEthernet.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiFlexray.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiLin.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiLogger.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiNetworkSimulator.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiOrchestration.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiParticipant.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiRpc.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiUtils.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiVendor.cpp");
    try O_SilKit_Capi_files.append("SilKit/source/capi/CapiVersion.cpp");
    var O_SilKit_Capi_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Capi_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Capi_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Capi_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Capi_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Capi_flags.append("-DUNIT_TEST");
    try O_SilKit_Capi_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Capi_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Capi_flags.append("-DNDEBUG");
    try O_SilKit_Capi_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Capi_flags);
    O_SilKit_Capi.addCSourceFiles(.{
        .files = O_SilKit_Capi_files.items,
        .flags = O_SilKit_Capi_flags.items,
    });
    O_SilKit_Capi.linkLibCpp();
    b.installArtifact(O_SilKit_Capi);

    const O_SilKit_CreateParticipantImpl: *Compile = b.addObject(.{
        .name = "O_SilKit_CreateParticipantImpl",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_CreateParticipantImpl);
    addIncludePath_ThirdParty(b, O_SilKit_CreateParticipantImpl);
    var O_SilKit_CreateParticipantImpl_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_CreateParticipantImpl_files.append("SilKit/source/CreateParticipantImpl.cpp");
    var O_SilKit_CreateParticipantImpl_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_CreateParticipantImpl_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_CreateParticipantImpl_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_CreateParticipantImpl_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_CreateParticipantImpl_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_CreateParticipantImpl_flags.append("-DUNIT_TEST");
    try O_SilKit_CreateParticipantImpl_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_CreateParticipantImpl_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_CreateParticipantImpl_flags.append("-DNDEBUG");
    try O_SilKit_CreateParticipantImpl_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_CreateParticipantImpl_flags);
    O_SilKit_CreateParticipantImpl.addCSourceFiles(.{
        .files = O_SilKit_CreateParticipantImpl_files.items,
        .flags = O_SilKit_CreateParticipantImpl_flags.items,
    });
    O_SilKit_CreateParticipantImpl.linkLibCpp();

    const O_SilKit_CreateSilKitRegistryImpl: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_CreateSilKitRegistryImpl",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_CreateSilKitRegistryImpl);
    addIncludePath_ThirdParty(b, O_SilKit_CreateSilKitRegistryImpl);
    var O_SilKit_CreateSilKitRegistryImpl_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_CreateSilKitRegistryImpl_files.append("SilKit/source/CreateSilKitRegistryImpl.cpp");
    try O_SilKit_CreateSilKitRegistryImpl_files.append("SilKit/source/CreateSilKitRegistryWithDashboard.cpp");
    var O_SilKit_CreateSilKitRegistryImpl_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_CreateSilKitRegistryImpl_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_CreateSilKitRegistryImpl_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_CreateSilKitRegistryImpl_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_CreateSilKitRegistryImpl_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_CreateSilKitRegistryImpl_flags.append("-DUNIT_TEST");
    try O_SilKit_CreateSilKitRegistryImpl_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_CreateSilKitRegistryImpl_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_CreateSilKitRegistryImpl_flags.append("-DNDEBUG");
    try O_SilKit_CreateSilKitRegistryImpl_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_CreateSilKitRegistryImpl_flags);
    O_SilKit_CreateSilKitRegistryImpl.addCSourceFiles(.{
        .files = O_SilKit_CreateSilKitRegistryImpl_files.items,
        .flags = O_SilKit_CreateSilKitRegistryImpl_flags.items,
    });
    O_SilKit_CreateSilKitRegistryImpl.linkLibCpp();
    b.installArtifact(O_SilKit_CreateSilKitRegistryImpl);

    const O_SilKit_VersionImpl: *Compile = b.addObject(.{
        .name = "O_SilKit_VersionImpl",
        .target = target,
        .optimize = optimize,
    });
    O_SilKit_VersionImpl.addIncludePath(b.path("SilKit/include"));
    O_SilKit_VersionImpl.addIncludePath(b.path("SilKit/source"));
    var O_SilKit_VersionImpl_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_VersionImpl_files.append("SilKit/source/SilKitVersionImpl.cpp");
    var O_SilKit_VersionImpl_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_VersionImpl_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_VersionImpl_flags.append("-DUNIT_TEST");
    try O_SilKit_VersionImpl_flags.append("-DNDEBUG");
    try O_SilKit_VersionImpl_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_VersionImpl_flags);
    O_SilKit_VersionImpl.addCSourceFiles(.{
        .files = O_SilKit_VersionImpl_files.items,
        .flags = O_SilKit_VersionImpl_flags.items,
    });
    O_SilKit_VersionImpl.linkLibCpp();

    const O_SilKitLegacyAbi: *Compile = b.addObject(.{
        .name = "O_SilKitLegacyAbi",
        .target = target,
        .optimize = optimize,
    });
    O_SilKitLegacyAbi.addIncludePath(b.path("SilKit/include"));
    O_SilKitLegacyAbi.addIncludePath(b.path("SilKit/source"));
    O_SilKitLegacyAbi.addIncludePath(b.path("SilKit/source/core"));
    O_SilKitLegacyAbi.addIncludePath(b.path("SilKit/source/config"));
    O_SilKitLegacyAbi.addIncludePath(b.path("SilKit/source/experimental"));
    O_SilKitLegacyAbi.addIncludePath(b.path("SilKit/source/experimental/SilKitInterface"));
    O_SilKitLegacyAbi.addIncludePath(b.path("SilKit/source/util"));
    O_SilKitLegacyAbi.addIncludePath(b.path("ThirdParty/yaml-cpp/include"));
    var O_SilKitLegacyAbi_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKitLegacyAbi_files.append("SilKit/source/LegacyAbi.cpp");
    var O_SilKitLegacyAbi_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKitLegacyAbi_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKitLegacyAbi_flags.append("-DUNIT_TEST");
    try O_SilKitLegacyAbi_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKitLegacyAbi_flags.append("-DNDEBUG");
    try O_SilKitLegacyAbi_flags.append("-std=gnu++14");
    try addFlags(&O_SilKitLegacyAbi_flags);
    O_SilKitLegacyAbi.addCSourceFiles(.{
        .files = O_SilKitLegacyAbi_files.items,
        .flags = O_SilKitLegacyAbi_flags.items,
    });
    O_SilKitLegacyAbi.linkLibCpp();

    const S_SilKitImpl: *Compile = b.addStaticLibrary(.{
        .name = "S_SilKitImpl",
        .target = target,
        .optimize = optimize,
    });
    S_SilKitImpl.linkLibrary(O_SilKit_Config);
    S_SilKitImpl.step.dependOn(&O_SilKit_Config.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Core_Participant);
    S_SilKitImpl.step.dependOn(&O_SilKit_Core_Participant.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Core_Service);
    S_SilKitImpl.step.dependOn(&O_SilKit_Core_Service.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Core_RequestReply);
    S_SilKitImpl.step.dependOn(&O_SilKit_Core_RequestReply.step);
    S_SilKitImpl.addObject(O_SilKit_Core_RequestReply_ParticipantReplies);
    S_SilKitImpl.step.dependOn(&O_SilKit_Core_RequestReply_ParticipantReplies.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Core_VAsio);
    S_SilKitImpl.step.dependOn(&O_SilKit_Core_VAsio.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Experimental);
    S_SilKitImpl.step.dependOn(&O_SilKit_Experimental.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Extensions);
    S_SilKitImpl.step.dependOn(&O_SilKit_Extensions.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Experimental_NetworkSimulatorInternals);
    S_SilKitImpl.step.dependOn(&O_SilKit_Experimental_NetworkSimulatorInternals.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Services_Can);
    S_SilKitImpl.step.dependOn(&O_SilKit_Services_Can.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Services_Ethernet);
    S_SilKitImpl.step.dependOn(&O_SilKit_Services_Ethernet.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Services_Flexray);
    S_SilKitImpl.step.dependOn(&O_SilKit_Services_Flexray.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Services_Lin);
    S_SilKitImpl.step.dependOn(&O_SilKit_Services_Lin.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Services_Logging);
    S_SilKitImpl.step.dependOn(&O_SilKit_Services_Logging.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Services_Orchestration);
    S_SilKitImpl.step.dependOn(&O_SilKit_Services_Orchestration.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Services_PubSub);
    S_SilKitImpl.step.dependOn(&O_SilKit_Services_PubSub.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Services_Rpc);
    S_SilKitImpl.step.dependOn(&O_SilKit_Services_Rpc.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Services_Metrics);
    S_SilKitImpl.step.dependOn(&O_SilKit_Services_Metrics.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Tracing);
    S_SilKitImpl.step.dependOn(&O_SilKit_Tracing.step);
    S_SilKitImpl.addObject(O_SilKit_Util);
    S_SilKitImpl.step.dependOn(&O_SilKit_Util.step);
    S_SilKitImpl.addObject(O_SilKit_Util_FileHelpers);
    S_SilKitImpl.step.dependOn(&O_SilKit_Util_FileHelpers.step);
    S_SilKitImpl.addObject(O_SilKit_Util_StringHelpers);
    S_SilKitImpl.step.dependOn(&O_SilKit_Util_StringHelpers.step);
    S_SilKitImpl.addObject(O_SilKit_Util_Filesystem);
    S_SilKitImpl.step.dependOn(&O_SilKit_Util_Filesystem.step);
    S_SilKitImpl.addObject(O_SilKit_Util_SetThreadName);
    S_SilKitImpl.step.dependOn(&O_SilKit_Util_SetThreadName.step);
    S_SilKitImpl.addObject(O_SilKit_Util_SignalHandler);
    S_SilKitImpl.step.dependOn(&O_SilKit_Util_SignalHandler.step);
    S_SilKitImpl.addObject(O_SilKit_Util_Uuid);
    S_SilKitImpl.step.dependOn(&O_SilKit_Util_Uuid.step);
    S_SilKitImpl.addObject(O_SilKit_Util_Uri);
    S_SilKitImpl.step.dependOn(&O_SilKit_Util_Uri.step);
    S_SilKitImpl.addObject(O_SilKit_Util_LabelMatching);
    S_SilKitImpl.step.dependOn(&O_SilKit_Util_LabelMatching.step);
    S_SilKitImpl.linkLibrary(O_SilKit_Capi);
    S_SilKitImpl.step.dependOn(&O_SilKit_Capi.step);
    S_SilKitImpl.addObject(O_SilKit_CreateParticipantImpl);
    S_SilKitImpl.step.dependOn(&O_SilKit_CreateParticipantImpl.step);
    S_SilKitImpl.linkLibrary(O_SilKit_CreateSilKitRegistryImpl);
    S_SilKitImpl.step.dependOn(&O_SilKit_CreateSilKitRegistryImpl.step);
    S_SilKitImpl.addObject(O_SilKit_VersionImpl);
    S_SilKitImpl.step.dependOn(&O_SilKit_VersionImpl.step);
    S_SilKitImpl.addObject(O_SilKitLegacyAbi);
    S_SilKitImpl.step.dependOn(&O_SilKitLegacyAbi.step);
    S_SilKitImpl.linkLibCpp();
    b.installArtifact(S_SilKitImpl);

    const O_SilKit_Dashboard: *Compile = b.addStaticLibrary(.{
        .name = "O_SilKit_Dashboard",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, O_SilKit_Dashboard);
    addIncludePath_ThirdParty(b, O_SilKit_Dashboard);
    var O_SilKit_Dashboard_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/Client/DashboardRetryPolicy.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/Client/DashboardSystemServiceClient.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/CreateDashboard.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/CreateDashboardInstance.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/Dashboard.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/DashboardBulkUpdate.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/DashboardInstance.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/DashboardParticipant.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/OatppContext.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/OatppHeaders.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/Service/CachingSilKitEventHandler.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/Service/SilKitEventHandler.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/Service/SilKitEventQueue.cpp");
    try O_SilKit_Dashboard_files.append("SilKit/source/dashboard/Service/SilKitToOatppMapper.cpp");
    var O_SilKit_Dashboard_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try O_SilKit_Dashboard_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try O_SilKit_Dashboard_flags.append("-DFMT_HEADER_ONLY");
    try O_SilKit_Dashboard_flags.append("-DFMT_HEADER_ONLY=1");
    try O_SilKit_Dashboard_flags.append("-DHAVE_FMTLIB");
    try O_SilKit_Dashboard_flags.append("-DUNIT_TEST");
    try O_SilKit_Dashboard_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try O_SilKit_Dashboard_flags.append("-D_WIN32_WINNT=0x0601");
    try O_SilKit_Dashboard_flags.append("-DNDEBUG");
    try O_SilKit_Dashboard_flags.append("-std=gnu++14");
    try addFlags(&O_SilKit_Dashboard_flags);
    O_SilKit_Dashboard.addCSourceFiles(.{
        .files = O_SilKit_Dashboard_files.items,
        .flags = O_SilKit_Dashboard_flags.items,
    });
    O_SilKit_Dashboard.linkLibCpp();
    b.installArtifact(O_SilKit_Dashboard);

    const sil_kit_registry: *Compile = b.addExecutable(.{
        .name = "sil-kit-registry",
        .target = target,
        .optimize = optimize,
    });
    addIncludePath_SilKit(b, sil_kit_registry);
    addIncludePath_ThirdParty(b, sil_kit_registry);
    sil_kit_registry.addIncludePath(b.path("Utilities/SilKitRegistry/config"));

    sil_kit_registry.linkLibrary(S_SilKitImpl);
    sil_kit_registry.step.dependOn(&S_SilKitImpl.step);

    sil_kit_registry.linkLibrary(spdlog);
    sil_kit_registry.step.dependOn(&spdlog.step);
    sil_kit_registry.linkLibrary(oatpp);
    sil_kit_registry.step.dependOn(&oatpp.step);
    sil_kit_registry.linkLibrary(yaml_cpp);
    sil_kit_registry.step.dependOn(&yaml_cpp.step);
    sil_kit_registry.linkLibrary(fmt);
    sil_kit_registry.step.dependOn(&fmt.step);

    var sil_kit_registry_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try sil_kit_registry_files.append("Utilities/SilKitRegistry/Registry_mod.cpp");
    var sil_kit_registry_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try sil_kit_registry_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try sil_kit_registry_flags.append("-DEXPORT_SilKitAPI");
    try sil_kit_registry_flags.append("-DFMT_HEADER_ONLY");
    try sil_kit_registry_flags.append("-DFMT_HEADER_ONLY=1");
    try sil_kit_registry_flags.append("-DHAVE_FMTLIB");
    try sil_kit_registry_flags.append("-DUNIT_TEST");
    try sil_kit_registry_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try sil_kit_registry_flags.append("-D_WIN32_WINNT=0x0601");
    try sil_kit_registry_flags.append("-DNDEBUG");
    try sil_kit_registry_flags.append("-std=gnu++14");
    try sil_kit_registry_flags.append("-fvisibility=hidden");
    //try sil_kit_registry_flags.append("-fno-keep-inline-dllexport");
    try sil_kit_registry_flags.append("-pedantic");
    try addWarningFlags(&sil_kit_registry_flags);
    sil_kit_registry.addCSourceFiles(.{
        .files = sil_kit_registry_files.items,
        .flags = sil_kit_registry_flags.items,
    });

    sil_kit_registry.linkSystemLibrary("wsock32");
    sil_kit_registry.linkSystemLibrary("ws2_32");
    sil_kit_registry.linkSystemLibrary("kernel32");
    sil_kit_registry.linkSystemLibrary("user32");
    sil_kit_registry.linkSystemLibrary("gdi32");
    sil_kit_registry.linkSystemLibrary("winspool");
    sil_kit_registry.linkSystemLibrary("shell32");
    sil_kit_registry.linkSystemLibrary("ole32");
    sil_kit_registry.linkSystemLibrary("oleaut32");
    sil_kit_registry.linkSystemLibrary("uuid");
    sil_kit_registry.linkSystemLibrary("comdlg32");
    sil_kit_registry.linkSystemLibrary("advapi32");
    sil_kit_registry.linkLibCpp();
    b.installArtifact(sil_kit_registry);

    const cm_include: LazyPath = .{ .cwd_relative = "C:/IPG/carmaker/win64-13.1.1/include" };
    const cm_lib: LazyPath = .{ .cwd_relative = "C:/IPG/carmaker/win64-13.1.1/lib" };
    const SilKitDemoCan: *Compile = b.addExecutable(.{
        .name = "SilKitDemoCan",
        .target = target,
        .optimize = optimize,
    });

    SilKitDemoCan.addIncludePath(cm_include);
    addIncludePath_SilKit(b, SilKitDemoCan);
    addIncludePath_ThirdParty(b, SilKitDemoCan);
    SilKitDemoCan.addIncludePath(b.path("Utilities/SilKitRegistry"));
    SilKitDemoCan.addIncludePath(b.path("Utilities/SilKitRegistry/config"));

    var SilKitDemoCan_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try SilKitDemoCan_files.append("Demos/Can/CanDemo.cpp");
    var SilKitDemoCan_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try SilKitDemoCan_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try SilKitDemoCan_flags.append("-DEXPORT_SilKitAPI");
    try SilKitDemoCan_flags.append("-DFMT_HEADER_ONLY");
    try SilKitDemoCan_flags.append("-DFMT_HEADER_ONLY=1");
    try SilKitDemoCan_flags.append("-DHAVE_FMTLIB");
    try SilKitDemoCan_flags.append("-DUNIT_TEST");
    try SilKitDemoCan_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try SilKitDemoCan_flags.append("-D_WIN32_WINNT=0x0601");
    try SilKitDemoCan_flags.append("-DNDEBUG");
    try SilKitDemoCan_flags.append("-std=gnu++14");
    try SilKitDemoCan_flags.append("-fvisibility=hidden");
    //try SilKitDemoCan_flags.append("-fno-keep-inline-dllexport");
    try SilKitDemoCan_flags.append("-pedantic");
    try addWarningFlags(&SilKitDemoCan_flags);
    SilKitDemoCan.addCSourceFiles(.{
        .files = SilKitDemoCan_files.items,
        .flags = SilKitDemoCan_flags.items,
    });

    SilKitDemoCan.addLibraryPath(cm_lib);
    SilKitDemoCan.linkLibrary(S_SilKitImpl);
    SilKitDemoCan.step.dependOn(&S_SilKitImpl.step);
    SilKitDemoCan.linkLibrary(spdlog);
    SilKitDemoCan.step.dependOn(&spdlog.step);
    SilKitDemoCan.linkLibrary(yaml_cpp);
    SilKitDemoCan.step.dependOn(&yaml_cpp.step);

    SilKitDemoCan.linkSystemLibrary("CM_vBUS-win64");
    SilKitDemoCan.linkSystemLibrary("wsock32");
    SilKitDemoCan.linkSystemLibrary("ws2_32");
    SilKitDemoCan.linkSystemLibrary("kernel32");
    SilKitDemoCan.linkSystemLibrary("user32");
    SilKitDemoCan.linkSystemLibrary("gdi32");
    SilKitDemoCan.linkSystemLibrary("winspool");
    SilKitDemoCan.linkSystemLibrary("shell32");
    SilKitDemoCan.linkSystemLibrary("ole32");
    SilKitDemoCan.linkSystemLibrary("oleaut32");
    SilKitDemoCan.linkSystemLibrary("uuid");
    SilKitDemoCan.linkSystemLibrary("comdlg32");
    SilKitDemoCan.linkSystemLibrary("advapi32");
    SilKitDemoCan.linkLibCpp();
    b.installArtifact(SilKitDemoCan);

    const CanReader: *Compile = b.addExecutable(.{
        .name = "CanReader",
        .target = target,
        .optimize = optimize,
    });

    addIncludePath_SilKit(b, CanReader);
    addIncludePath_ThirdParty(b, CanReader);
    CanReader.addIncludePath(b.path("Utilities/SilKitRegistry"));
    CanReader.addIncludePath(b.path("Utilities/SilKitRegistry/config"));
    CanReader.addIncludePath(cm_include);

    var CanReader_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try CanReader_files.append("Demos/Can/CanReader.cpp");
    var CanReader_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try CanReader_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try CanReader_flags.append("-DEXPORT_SilKitAPI");
    try CanReader_flags.append("-DFMT_HEADER_ONLY");
    try CanReader_flags.append("-DFMT_HEADER_ONLY=1");
    try CanReader_flags.append("-DHAVE_FMTLIB");
    try CanReader_flags.append("-DUNIT_TEST");
    try CanReader_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try CanReader_flags.append("-D_WIN32_WINNT=0x0601");
    try CanReader_flags.append("-DNDEBUG");
    try CanReader_flags.append("-std=gnu++14");
    try CanReader_flags.append("-fvisibility=hidden");
    //try CanReader_flags.append("-fno-keep-inline-dllexport");

    try CanReader_flags.append("-pedantic");
    try addWarningFlags(&CanReader_flags);
    CanReader.addCSourceFiles(.{
        .files = CanReader_files.items,
        .flags = CanReader_flags.items,
    });

    CanReader.addLibraryPath(cm_lib);
    CanReader.linkLibrary(S_SilKitImpl);
    CanReader.step.dependOn(&S_SilKitImpl.step);
    CanReader.linkLibrary(spdlog);
    CanReader.step.dependOn(&spdlog.step);
    CanReader.linkLibrary(yaml_cpp);
    CanReader.step.dependOn(&yaml_cpp.step);

    CanReader.linkSystemLibrary("CM_vBUS-win64");
    CanReader.linkSystemLibrary("wsock32");
    CanReader.linkSystemLibrary("ws2_32");
    CanReader.linkSystemLibrary("kernel32");
    CanReader.linkSystemLibrary("user32");
    CanReader.linkSystemLibrary("gdi32");
    CanReader.linkSystemLibrary("winspool");
    CanReader.linkSystemLibrary("shell32");
    CanReader.linkSystemLibrary("ole32");
    CanReader.linkSystemLibrary("oleaut32");
    CanReader.linkSystemLibrary("uuid");
    CanReader.linkSystemLibrary("comdlg32");
    CanReader.linkSystemLibrary("advapi32");
    CanReader.linkLibCpp();
    b.installArtifact(CanReader);

    const CanWriter: *Compile = b.addExecutable(.{
        .name = "CanWriter",
        .target = target,
        .optimize = optimize,
    });

    addIncludePath_SilKit(b, CanWriter);
    addIncludePath_ThirdParty(b, CanWriter);
    CanWriter.addIncludePath(b.path("Utilities/SilKitRegistry"));
    CanWriter.addIncludePath(b.path("Utilities/SilKitRegistry/config"));
    CanWriter.addIncludePath(cm_include);

    var CanWriter_files: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try CanWriter_files.append("Demos/Can/CanWriter.cpp");
    var CanWriter_flags: std.ArrayListAligned([]const u8, null) = std.ArrayList([]const u8).init(b.allocator);
    try CanWriter_flags.append("-DASIO_DISABLE_VISIBILITY=1");
    try CanWriter_flags.append("-DEXPORT_SilKitAPI");
    try CanWriter_flags.append("-DFMT_HEADER_ONLY");
    try CanWriter_flags.append("-DFMT_HEADER_ONLY=1");
    try CanWriter_flags.append("-DHAVE_FMTLIB");
    try CanWriter_flags.append("-DUNIT_TEST");
    try CanWriter_flags.append("-DYAML_CPP_STATIC_DEFINE");
    try CanWriter_flags.append("-D_WIN32_WINNT=0x0601");
    try CanWriter_flags.append("-DNDEBUG");
    try CanWriter_flags.append("-std=gnu++14");
    try CanWriter_flags.append("-fvisibility=hidden");
    //try CanWriter_flags.append("-fno-keep-inline-dllexport");
    try CanWriter_flags.append("-pedantic");
    try addWarningFlags(&CanWriter_flags);
    CanWriter.addCSourceFiles(.{
        .files = CanWriter_files.items,
        .flags = CanWriter_flags.items,
    });

    CanWriter.addLibraryPath(cm_lib);
    CanWriter.linkLibrary(S_SilKitImpl);
    CanWriter.step.dependOn(&S_SilKitImpl.step);
    CanWriter.linkLibrary(spdlog);
    CanWriter.step.dependOn(&spdlog.step);
    CanWriter.linkLibrary(yaml_cpp);
    CanWriter.step.dependOn(&yaml_cpp.step);

    CanWriter.linkSystemLibrary("CM_vBUS-win64");
    CanWriter.linkSystemLibrary("wsock32");
    CanWriter.linkSystemLibrary("ws2_32");
    CanWriter.linkSystemLibrary("kernel32");
    CanWriter.linkSystemLibrary("user32");
    CanWriter.linkSystemLibrary("gdi32");
    CanWriter.linkSystemLibrary("winspool");
    CanWriter.linkSystemLibrary("shell32");
    CanWriter.linkSystemLibrary("ole32");
    CanWriter.linkSystemLibrary("oleaut32");
    CanWriter.linkSystemLibrary("uuid");
    CanWriter.linkSystemLibrary("comdlg32");
    CanWriter.linkSystemLibrary("advapi32");
    CanWriter.linkLibCpp();
    b.installArtifact(CanWriter);
}
