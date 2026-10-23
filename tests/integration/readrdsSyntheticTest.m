classdef readrdsSyntheticTest < matlab.unittest.TestCase
    %readrdsSyntheticTest Tests public .rds imports using R-generated fixtures.

% Copyright 2026 The MathWorks, Inc.

    properties
        FixtureRoot (1,1) string
    end

    methods (TestClassSetup)
        function prepareFixtures(testCase)
            testCase.FixtureRoot = rdata.test.generateSyntheticFixtures(currentProject().RootFolder);
        end
    end

    methods (Test, TestTags = {'Synthetic'})
        function testIntegerVector(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");

            [value, metadata] = readrds(fixture);

            testCase.verifyEqual(value([1 2 3 5]), [-10; 0; 25; 100])
            testCase.verifyTrue(isnan(value(4)))
            testCase.verifyEqual(metadata.Missing, [false; false; false; true; false])
        end

        function testLogicalVector(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "logical_vector.rds");

            [value, metadata] = readrds(fixture);

            testCase.verifyEqual(value, [true; false; false])
            testCase.verifyEqual(metadata.Missing, [false; false; true])
        end

        function testRealVector(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "real_vector.rds");

            [value, metadata] = readrds(fixture);

            testCase.verifyEqual(value([1 4 5]), [1.5; Inf; -Inf])
            testCase.verifyTrue(isnan(value(2)))
            testCase.verifyTrue(isnan(value(3)))
            testCase.verifyEqual(1/value(6), -Inf)
            testCase.verifyEqual(metadata.Missing, [false; true; false; false; false; false])
        end

        function testComplexVector(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "complex_vector.rds");

            [value, metadata] = readrds(fixture);

            testCase.verifyEqual(value(1), 1 + 2i)
            testCase.verifyTrue(isnan(real(value(2))))
            testCase.verifyTrue(isnan(imag(value(2))))
            testCase.verifyEqual(metadata.Missing, [false; true; false])
        end

        function testRawVector(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "raw_vector.rds");

            value = readrds(fixture);

            testCase.verifyEqual(value, uint8([0; 1; 127; 128; 255]))
        end

        function testCharacterVector(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "character_vector.rds");

            [value, metadata] = readrds(fixture);
            expected = string(native2unicode(uint8([195 169]), "UTF-8"));

            testCase.verifyEqual(value(1), "abc")
            testCase.verifyTrue(ismissing(value(2)))
            testCase.verifyEqual(value(3), expected)
            testCase.verifyEqual(metadata.Missing, [false; true; false])
        end

        function testLatin1CharacterMetadata(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "latin1_vector.rds");

            [value, metadata] = readrds(fixture);
            expected = string(native2unicode(uint8([195 169]), "UTF-8"));

            testCase.verifyEqual(value, expected)
            testCase.verifyEqual(metadata.Encoding, "latin1")
        end

        function testByteMarkedStringMetadata(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "bytes_vector.rds");

            [value, metadata] = readrds(fixture);
            expectedValue = string(native2unicode(uint8([128 129]), "ISO-8859-1"));

            testCase.verifyEqual(value, expectedValue)
            testCase.verifyEqual(metadata.Encoding, "bytes")
            testCase.verifyEqual(metadata.RawBytes{1}, uint8([128 129]))
        end

        function testCellstrUsesEmptyCharForMissing(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "character_empty_vector.rds");

            [value, metadata] = readrds(fixture, TextType="cellstr");

            testCase.verifyTrue(iscellstr(value)) %#ok<ISCLSTR>
            testCase.verifyEqual(value{1}, '')
            testCase.verifyEqual(value{2}, '')
            testCase.verifyEqual(metadata.Missing, [false; true])
        end

        function testNamedIntegerMetadata(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "named_integer.rds");

            [value, metadata] = readrds(fixture);

            testCase.verifyEqual(value(1), 10)
            testCase.verifyTrue(isnan(value(2)))
            testCase.verifyEqual(metadata.Names, ["alpha"; "beta"])
        end

        function testGzipRds(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector_gzip.rds");

            [value, metadata] = readrds(fixture);

            testCase.verifyEqual(value([1 2 3 5]), [-10; 0; 25; 100])
            testCase.verifyEqual(metadata.Compression, "gzip")
        end

        function testVersion2Rds(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector_v2.rds");

            [value, metadata] = readrds(fixture);

            testCase.verifyEqual(value([1 2 3 5]), [-10; 0; 25; 100])
            testCase.verifyEqual(metadata.SerializationVersion, 2)
        end

        function testNativeBinaryRds(testCase)
            fixture = string(tempname) + ".rds";
            writeNativeIntegerRds(fixture, int32([7; -3; intmin("int32")]));
            testCase.addTeardown(@() delete(fixture));

            [value, metadata] = readrds(fixture);

            testCase.verifyEqual(value(1:2), [7; -3])
            testCase.verifyTrue(isnan(value(3)))
            testCase.verifyEqual(metadata.SerializationFormat, "native")
        end

        function testNativeRealRdsDistinguishesNaFromNan(testCase)
            fixture = string(tempname) + ".rds";
            valueBits = [
                doubleBits(1.5)
                rNaBits()
                ordinaryNaNBits()
                doubleBits(Inf)
            ];
            writeNativeAtomicRds(fixture, "REALSXP", ...
                nativeUInt64Bytes(valueBits), numel(valueBits));
            testCase.addTeardown(@() delete(fixture));

            [value, metadata] = readrds(fixture);

            testCase.verifyEqual(value(1), 1.5, AbsTol=0)
            testCase.verifyTrue(isnan(value(2)))
            testCase.verifyTrue(isnan(value(3)))
            testCase.verifyEqual(value(4), Inf)
            testCase.verifyEqual(metadata.Missing, [false; true; false; false])
        end

        function testNativeComplexRdsMissingValues(testCase)
            fixture = string(tempname) + ".rds";
            valueBits = [
                doubleBits(1)
                doubleBits(2)
                rNaBits()
                doubleBits(2)
                ordinaryNaNBits()
                doubleBits(3)
            ];
            writeNativeAtomicRds(fixture, "CPLXSXP", ...
                nativeUInt64Bytes(valueBits), 3);
            testCase.addTeardown(@() delete(fixture));

            [value, metadata] = readrds(fixture);

            testCase.verifyEqual(value(1), 1 + 2i, AbsTol=0)
            testCase.verifyTrue(isnan(real(value(2))))
            testCase.verifyEqual(imag(value(2)), 2, AbsTol=0)
            testCase.verifyTrue(isnan(real(value(3))))
            testCase.verifyEqual(imag(value(3)), 3, AbsTol=0)
            testCase.verifyEqual(metadata.Missing, [false; true; false])
        end
    end
end

function writeNativeIntegerRds(filename, values)
writeNativeAtomicRds(filename, "INTSXP", ...
    reshape(typecast(values.', "uint8"), 1, []), numel(values))
end

function writeNativeAtomicRds(filename, type, payloadBytes, numElements)
bytes = [
    uint8('B') uint8(10) ...
    nativeUInt32Bytes(3) ...
    nativeUInt32Bytes(packRVersion("4.3.0")) ...
    nativeUInt32Bytes(packRVersion("3.5.0")) ...
    nativeUInt32Bytes(0) ...
    nativeUInt32Bytes(rdata.internal.RType.(type)) ...
    nativeUInt32Bytes(numElements) ...
    payloadBytes
];

writeBytes(filename, bytes)
end

function value = packRVersion(versionText)
parts = sscanf(char(versionText), "%d.%d.%d");
value = uint32(parts(1)*65536 + parts(2)*256 + parts(3));
end

function bytes = nativeUInt32Bytes(value)
bytes = reshape(typecast(uint32(value), "uint8"), 1, []);
end

function bytes = nativeUInt64Bytes(value)
bytes = reshape(typecast(uint64(value(:).'), "uint8"), 1, []);
end

function bits = doubleBits(value)
bits = typecast(double(value), "uint64");
end

function bits = rNaBits()
bits = bitor( ...
    bitshift(uint64(hex2dec("7FF00000")), 32), ...
    uint64(hex2dec("000007A2")));
end

function bits = ordinaryNaNBits()
bits = bitshift(uint64(hex2dec("7FF80000")), 32);
end

function writeBytes(filename, bytes)
fileId = fopen(filename, "wb");
if fileId < 0
    error("rdata:TestFileError", "Unable to create temporary test file.")
end
cleanup = onCleanup(@() fclose(fileId));
fwrite(fileId, bytes, "uint8");
end
