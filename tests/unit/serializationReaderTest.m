classdef serializationReaderTest < matlab.unittest.TestCase
    %serializationReaderTest Tests for the XDR serialization byte reader.

% Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function testReadInt32(testCase)
            reader = rdata.internal.SerializationReader(uint8([255 255 255 255]), "XDR");

            value = reader.readInt32();

            testCase.verifyEqual(value, int32(-1))
        end

        function testReadInt32ArrayXdr(testCase)
            bytes = uint8([0 0 0 1, 255 255 255 254, 128 0 0 0]);
            reader = rdata.internal.SerializationReader(bytes, "XDR");

            values = reader.readInt32Array(3);

            testCase.verifyEqual(values, int32([1; -2; intmin("int32")]))
            testCase.verifyEqual(reader.Position, 13)
        end

        function testReadInt32ArrayNative(testCase)
            expected = int32([1; -2; intmin("int32")]);
            bytes = reshape(typecast(expected.', "uint8"), 1, []);
            reader = rdata.internal.SerializationReader(bytes, "native");

            values = reader.readInt32Array(3);

            testCase.verifyEqual(values, expected)
        end

        function testReadUInt32(testCase)
            reader = rdata.internal.SerializationReader(uint8([0 0 1 0]), "XDR");

            value = reader.readUInt32();

            testCase.verifyEqual(value, uint32(256))
        end

        function testReadDouble(testCase)
            reader = rdata.internal.SerializationReader(uint8([63 248 0 0 0 0 0 0]), "XDR");

            value = reader.readDouble();

            testCase.verifyEqual(value, 1.5, AbsTol=0)
        end

        function testReadDoubleArrayXdr(testCase)
            expected = [1.5; -2.25; Inf];
            reader = rdata.internal.SerializationReader(xdrDoubleBytes(expected), "XDR");

            [values, rawBytes] = reader.readDoubleArray(3);

            testCase.verifyEqual(values, expected, AbsTol=0)
            testCase.verifySize(rawBytes, [8 3])
            testCase.verifyEqual(reader.Position, 25)
        end

        function testReadDoubleArrayNative(testCase)
            expected = [1.5; -2.25; Inf];
            bytes = reshape(typecast(expected.', "uint8"), 1, []);
            reader = rdata.internal.SerializationReader(bytes, "native");

            [values, rawBytes] = reader.readDoubleArray(3);

            testCase.verifyEqual(values, expected, AbsTol=0)
            testCase.verifySize(rawBytes, [8 3])
        end

        function testHostEndianIsCached(testCase)
            reader = rdata.internal.SerializationReader(uint8.empty(1, 0), "XDR");
            [~, ~, expected] = computer;

            testCase.verifyEqual(reader.HostEndian, string(expected))
        end

        function testUnexpectedEndOfFile(testCase)
            reader = rdata.internal.SerializationReader(uint8([1 2 3]), "XDR");

            testCase.verifyError(@() reader.readInt32(), "rdata:UnexpectedEndOfFile")
        end

        function testBulkUnexpectedEndOfFile(testCase)
            reader = rdata.internal.SerializationReader(zeros(1, 7, "uint8"), "XDR");

            testCase.verifyError(@() reader.readInt32Array(2), "rdata:UnexpectedEndOfFile")
        end
    end
end

function bytes = xdrDoubleBytes(values)
bytes = reshape(typecast(values.', "uint8"), 8, []);
[~, ~, endian] = computer;
if endian == "L"
    bytes = flipud(bytes);
end
bytes = reshape(bytes, 1, []);
end
