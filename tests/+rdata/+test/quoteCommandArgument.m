function quoted = quoteCommandArgument(argument)
%QUOTECOMMANDARGUMENT Quote one command-line argument for system().

% Copyright 2026 The MathWorks, Inc.

argument = string(argument);
quoted = """" + replace(argument, """", "\""") + """";
end

