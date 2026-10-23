classdef SerializationReader < handle
    %SERIALIZATIONREADER Cursor over an R binary serialization byte stream.

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = private)
        Bytes (1,:) uint8
        Format (1,1) string
        HostEndian (1,1) string
    end

    properties
        Position (1,1) double = 1
    end

    methods
        function reader = SerializationReader(bytes, format)
            arguments
                bytes (1,:) uint8
                format (1,1) string {mustBeMember(format, ["XDR", "native"])}
            end

            reader.Bytes = bytes;
            reader.Format = format;
            [~, ~, endian] = computer;
            reader.HostEndian = string(endian);
        end

        function tf = hasBytes(reader, n)
            arguments
                reader (1,1) rdata.internal.SerializationReader
                n (1,1) double {mustBeNonnegative}
            end

            tf = reader.Position + n - 1 <= numel(reader.Bytes);
        end

        function value = readUInt8(reader)
            bytes = reader.readBytes(1);
            value = bytes(1);
        end

        function bytes = readBytes(reader, n)
            arguments
                reader (1,1) rdata.internal.SerializationReader
                n (1,1) double {mustBeNonnegative}
            end

            if ~reader.hasBytes(n)
                error("rdata:UnexpectedEndOfFile", ...
                    "Unexpected end of R serialization stream at byte position %d.", reader.Position)
            end

            firstIndex = reader.Position;
            lastIndex = reader.Position + n - 1;
            bytes = reader.Bytes(firstIndex:lastIndex);
            reader.Position = lastIndex + 1;
        end

        function value = readInt32(reader)
            value = reader.readInt32Array(1);
        end

        function values = readInt32Array(reader, n)
            unsignedValues = reader.readUInt32Array(n);
            values = reshape(typecast(unsignedValues, "int32"), [], 1);
        end

        function value = readUInt32(reader)
            value = reader.readUInt32Array(1);
        end

        function values = readUInt32Array(reader, n)
            bytes = reader.readBytes(4*n);
            values = typecast(bytes, "uint32");
            if reader.Format == "XDR" && reader.HostEndian == "L"
                values = swapbytes(values);
            end
            values = values(:);
        end

        function [value, rawBytes] = readDouble(reader)
            [value, rawByteColumns] = reader.readDoubleArray(1);
            rawBytes = rawByteColumns(:, 1).';
        end

        function [values, rawBytes] = readDoubleArray(reader, n)
            rawBytes = reshape(reader.readBytes(8*n), 8, []);
            machineBytes = reshape(rawBytes, 1, []);
            values = typecast(machineBytes, "double");
            if reader.Format == "XDR" && reader.HostEndian == "L"
                values = swapbytes(values);
            end
            values = values(:);
        end
    end
end
