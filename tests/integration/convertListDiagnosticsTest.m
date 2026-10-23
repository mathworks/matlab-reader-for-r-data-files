classdef convertListDiagnosticsTest < matlab.unittest.TestCase
    %convertListDiagnosticsTest Tests list conversion and diagnostics.

% Copyright 2026 The MathWorks, Inc.

    properties
        FixtureRoot (1,1) string
    end

    properties (TestParameter)
        environmentCase = struct( ...
            base=struct(Filename="base_environment.rds", Type="BASEENV_SXP", Raw=uint32(241)), ...
            empty=struct(Filename="empty_environment.rds", Type="EMPTYENV_SXP", Raw=uint32(242)), ...
            globalEnvironment=struct(Filename="global_environment.rds", Type="GLOBALENV_SXP", Raw=uint32(253)));
    end

    methods (TestClassSetup)
        function prepareFixtures(testCase)
            testCase.FixtureRoot = rdata.test.generateSyntheticFixtures(currentProject().RootFolder);
        end
    end

    methods (Test, TestTags = {'Synthetic'})
        function testUnnamedList(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "unnamed_list.rds");

            value = readrds(fixture);

            testCase.verifyClass(value, "cell")
            testCase.verifyEqual(value{1}(1), 1.5)
            testCase.verifyTrue(isnan(value{1}(2)))
            testCase.verifyEqual(value{2}(1), "x")
            testCase.verifyTrue(ismissing(value{2}(2)))
            testCase.verifyEmpty(value{3})
        end

        function testNamedList(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "named_list.rds");

            value = readrds(fixture);

            testCase.verifyClass(value, "dictionary")
            testCase.verifyEqual(value{"first"}(1), 1)
            testCase.verifyTrue(isnan(value{"first"}(2)))
            testCase.verifyEqual(value{"second"}, ["a"; "b"])
        end

        function testNestedList(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "nested_list.rds");

            value = readrds(fixture);

            outer = value{"outer"};
            testCase.verifyTrue(outer{"inner"}(1))
            testCase.verifyFalse(outer{"inner"}(2))
            testCase.verifyEqual(value{"value"}, 42)
        end

        function testInvalidNameReturnsDictionary(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "invalid_name_list.rds");

            rds = readrds(fixture);
            testCase.verifyClass(rds, "dictionary");
            testCase.verifyEqual(rds.keys, ["bad-name"; "bad/name"]);
        end

        function testCompactAltrepSequence(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "altrep_sequence.rds");

            value = readrds(fixture);

            testCase.verifyEqual(value, [1; 2; 3])
        end

        function testFunctionDiagnostic(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "function_object.rds");

            testCase.verifyError(@() readrds(fixture), "rdata:UnsupportedRType")
        end

        function testFunctionOpaqueMode(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "function_object.rds");

            value = readrds(fixture, PreserveUnsupported="opaque");

            testCase.verifyTrue(value.Unsupported)
            testCase.verifyEqual(value.RType, "CLOSXP")
        end

        function testFunctionRawMode(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "function_object.rds");

            value = readrds(fixture, PreserveUnsupported="raw");

            testCase.verifyEqual(value.Type, "CLOSXP")
            testCase.verifyTrue(isfield(value.Value, "Body"))
            testCase.verifyEqual(value.Value.Formals.Value.Car.Type, "MISSINGARG_SXP")
        end

        function testEnvironmentDiagnostic(testCase, environmentCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", environmentCase.Filename);

            testCase.verifyError(@() readrds(fixture), "rdata:UnsupportedRType")
        end

        function testEnvironmentOpaqueMode(testCase, environmentCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", environmentCase.Filename);

            value = readrds(fixture, PreserveUnsupported="opaque");

            testCase.verifyTrue(value.Unsupported)
            testCase.verifyEqual(value.RType, environmentCase.Type)
        end

        function testEnvironmentRawMode(testCase, environmentCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", environmentCase.Filename);

            value = readrds(fixture, PreserveUnsupported="raw");

            testCase.verifyEqual(value.Type, environmentCase.Type)
            testCase.verifyEqual(value.Info.Raw, environmentCase.Raw)
        end

        function testNestedUnsupportedOpaqueMode(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "list_with_function.rds");

            value = readrds(fixture, PreserveUnsupported="opaque");
            placeholder = value{"bad"};

            testCase.verifyEqual(value{"ok"}, [1; 2])
            testCase.verifyTrue(placeholder.Unsupported)
            testCase.verifyEqual(placeholder.RType, "CLOSXP")
        end

        function testFormulaOpaqueMode(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "formula_object.rds");

            value = readrds(fixture, PreserveUnsupported="opaque");

            testCase.verifyTrue(value.Unsupported)
            testCase.verifyEqual(value.RType, "LANGSXP")
            testCase.verifyEqual(value.RClass, "formula")
        end

        function testGzipDeclaredSizeLimit(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector_gzip.rds");
            limits = rdata.internal.defaultLimits();
            limits.MaxDecompressedBytes = 10;

            testCase.verifyError( ...
                @() rdata.internal.parseRFileEnvelope(fixture, limits), ...
                "rdata:DecompressedDataTooLarge")
        end

        function testMaxObjectCountLimit(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");

            options = struct( ...
                TextType="string", ...
                IntegerType="double", ...
                PreserveUnsupported="error", ...
                AttachMetadata=true, ...
                Limits=rdata.internal.defaultLimits());
            
            options.Limits.MaxObjectCount = 0;

            testCase.verifyError( ...
                @()  rdata.internal.parseRFile(fixture, options, "RDS"), ...
                "rdata:ObjectLimitExceeded")
        end

        function testMaxRecursionDepthLimit(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "nested_list.rds");
            options = struct( ...
                TextType="string", ...
                IntegerType="double", ...
                PreserveUnsupported="error", ...
                AttachMetadata=true, ...
                Limits=rdata.internal.defaultLimits());
            options.Limits.MaxRecursionDepth = 0;

            testCase.verifyError( ...
                @() rdata.internal.parseRFile(fixture, options, "RDS"), ...
                "rdata:RecursionLimitExceeded")
        end

        function testMaxVectorElementsLimit(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");
            options = struct( ...
                TextType="string", ...
                IntegerType="double", ...
                PreserveUnsupported="error", ...
                AttachMetadata=true, ...
                Limits=rdata.internal.defaultLimits());
            options.Limits.MaxVectorElements = 1;

            testCase.verifyError( ...
                @() rdata.internal.parseRFile(fixture, options, "RDS"), ...
                "rdata:VectorTooLarge")
        end

        function testMaxStringBytesLimit(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "character_vector.rds");
            options = struct( ...
                TextType="string", ...
                IntegerType="double", ...
                PreserveUnsupported="error", ...
                AttachMetadata=true, ...
                Limits=rdata.internal.defaultLimits());
            options.Limits.MaxStringBytes = 0;

            testCase.verifyError( ...
                @() rdata.internal.parseRFile(fixture, options, "RDS"), ...
                "rdata:StringTooLarge")
        end

        function testMaxCompressedBytesLimit(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");
            options = struct(Limits=rdata.internal.defaultLimits());
            options.Limits.MaxCompressedBytes = 1;

            testCase.verifyError( ...
                @() rdata.internal.parseRFile(fixture, options, "RDS"), ...
                "rdata:FileTooLarge")
        end

        function testUnsupportedSerializationVersion(testCase)
            fixture = string(tempname) + ".rds";
            payloadBytes = serializationVersionBytes(99, "4.3.0", "3.5.0");
            writeMinimalRdsStream(fixture, "X", payloadBytes)
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() readrds(fixture), "rdata:UnsupportedSerializationVersion")
        end

        function testInvalidSexpTypeDiagnostic(testCase)
            fixture = string(tempname) + ".rds";
            payloadBytes = [
                serializationVersionBytes(3, "4.3.0", "3.5.0") ...
                uint32Bytes(200)
            ];
            writeMinimalRdsStream(fixture, "X", payloadBytes)
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() readrds(fixture), "rdata:UnsupportedRType")
        end

        function testCsvWithRdsExtensionDiagnostic(testCase)
            fixture = string(tempname) + ".rds";
            writeBytes(fixture, uint8(sprintf('a,b\n1,2\n')))
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() readrds(fixture), "rdata:InvalidHeader")
        end

        function testTrailingGarbageDiagnostic(testCase)
            source = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");
            fixture = string(tempname) + ".rds";
            bytes = rdata.internal.readFileBytes(source);
            writeBytes(fixture, [bytes uint8([1 2 3])])
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() readrds(fixture), "rdata:InvalidHeader")
        end

        function testBzip2Diagnostic(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector_bzip2.rds");

            testCase.verifyError(@() readrds(fixture), "rdata:UnsupportedCompression")
        end

        function testXzDiagnostic(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector_xz.rds");

            testCase.verifyError(@() readrds(fixture), "rdata:UnsupportedCompression")
        end

        function testZstdDiagnostic(testCase)
            fixture = string(tempname) + ".rds";
            writeBytes(fixture, uint8([40 181 47 253]))
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() readrds(fixture), "rdata:UnsupportedCompression")
        end

        function testTruncatedNativeBinaryDiagnostic(testCase)
            fixture = string(tempname) + ".rds";
            payloadBytes = serializationVersionBytes(3, "4.3.0", "3.5.0", "native");
            writeMinimalRdsStream(fixture, "B", payloadBytes)
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() readrds(fixture), "rdata:UnexpectedEndOfFile")
        end

        function testAsciiDiagnostic(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector_ascii.rds");

            testCase.verifyError(@() readrds(fixture), "rdata:UnsupportedSerializationFormat")
        end

        function testAsciiRDataDiagnostic(testCase)
            fixture = string(tempname) + ".rda";
            payloadBytes = serializationVersionBytes(3, "4.3.0", "3.5.0");
            writeMinimalRDataStream(fixture, "RDA3", "A", payloadBytes)
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() readrdata(fixture), "rdata:UnsupportedSerializationFormat")
        end

        function testTruncatedStreamDiagnostic(testCase)
            source = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");
            fixture = fullfile(tempdir, "truncated-r-stream.rds");
            bytes = rdata.internal.readFileBytes(source);
            writeBytes(fixture, bytes(1:end - 2))
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() readrds(fixture), "rdata:UnexpectedEndOfFile")
        end

        function testTruncatedGzipDiagnostic(testCase)
            source = fullfile(testCase.FixtureRoot, "rds", "integer_vector_gzip.rds");
            fixture = fullfile(tempdir, "truncated-r-stream.rds.gz");
            bytes = rdata.internal.readFileBytes(source);
            writeBytes(fixture, bytes(1:end - 2))
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() readrds(fixture), "rdata:InvalidHeader")
        end
    end
end

function writeBytes(filename, bytes)
fileId = fopen(filename, "wb");
if fileId < 0
    error("rdata:TestFileError", "Unable to create temporary test file.")
end
cleanup = onCleanup(@() fclose(fileId));
fwrite(fileId, bytes, "uint8");
end

function writeMinimalRdsStream(filename, formatLine, payloadBytes)
bytes = [uint8(char(formatLine)) uint8(10) uint8(payloadBytes)];
writeBytes(filename, bytes)
end

function writeMinimalRDataStream(filename, saveHeader, formatLine, payloadBytes)
bytes = [
    uint8(char(saveHeader)) uint8(10) ...
    uint8(char(formatLine)) uint8(10) ...
    uint8(payloadBytes)
];
writeBytes(filename, bytes)
end

function bytes = serializationVersionBytes(version, writerVersion, minReaderVersion, byteOrder)
if nargin < 4
    byteOrder = "XDR";
end
bytes = [
    uint32Bytes(version, byteOrder) ...
    versionBytes(writerVersion, byteOrder) ...
    versionBytes(minReaderVersion, byteOrder)
];
if version >= 3
    bytes = [bytes uint32Bytes(0, byteOrder)];
end
end

function bytes = versionBytes(versionText, byteOrder)
parts = sscanf(char(versionText), "%d.%d.%d");
packedVersion = uint32(parts(1)*65536 + parts(2)*256 + parts(3));
bytes = uint32Bytes(packedVersion, byteOrder);
end

function bytes = uint32Bytes(value, byteOrder)
if nargin < 2
    byteOrder = "XDR";
end
value = uint32(value);
if byteOrder == "native"
    bytes = typecast(value, "uint8");
else
    bytes = uint8([
        bitshift(value, -24) ...
        bitand(bitshift(value, -16), 255) ...
        bitand(bitshift(value, -8), 255) ...
        bitand(value, 255)
    ]);
end
end
