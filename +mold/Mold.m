classdef Mold < handle
    %#ok<*AGROW>
    %#ok<*NASGU> 

    properties
        % METHODS: An struct whose field are any additional commands that the
        % mold can parse, and whose values are the callbacks executed when the
        % commands are found. Note: the callbacks must return a string to
        % replace the command
        Methods struct % = struct("my-command", @(args) myCallback(...args) ,...)
    end
    properties (Access = private)
        Env struct
    end

    methods
        function this = Mold(env)
            % MOLD constructor. 
            % optionally takes a struct defining environment variables that will
            % be used every time the mold bakes something
            arguments
                env (1,1) struct = struct();
            end
            this.Env = env;
            this.Methods = struct();
        end

        function fn = bake(this, text)
            % BAKE precompiles the input text and returns a function that can be
            % evaluated with a struct(). The struct represents the $in element
            % used within the text directives
            arguments
                this (1,1) mold.Mold
                text (1,1) string
            end
            fn = @(in) evaluate(in, compile(text), this);
        end
    end

    methods (Hidden)

        function out = escapeHTML(~, text)
            % ESCAPEHTML is an INTERNAL method. Escapes the >,&," characters
            arguments
                ~
                text (1,1) string
            end
            HTMLspecial = containers.Map(["<","&", """"], ["&lt;", "&amp;", "&quot;"]);
            out = regexprep(text, "[<&\""]", "${HTMLspecial($&)}");
        end

        function str = dispatch(this, command, varargin)
            % DISPATCH is an internal method. Evaluates the method callback with
            % the given arguments (comma separated)
            str = feval(this.Methods.(command), varargin{:});
        end
    end
end


function parts = tokenize(text)
parts = cell.empty();
pos = 0;

    function addString(text)
        % remove leading newlines and whitespaces
        [~, before] = regexp(text, "^\n\s*");
        if before
            text = extractAfter(text, before);
        end

        % remove trailing newline and whitespaces
        after = regexp(text, "\n\s*$");
        if after
            text = extractBefore(text, after);
        end

        if strlength(text)
            parts{end + 1} = text;
        end
    end

while true
    open = strfind(extractAfter(text, pos), "<<") + pos;
    if isempty(open)
        addString(extractAfter(text, pos));
        return;
    else
        open = open(1);
        while any(strfind(text, "<") == open+2)
            open = open + 1;
        end
        addString(extractBetween(text, pos, open, "Boundaries", "exclusive"))
        close = strfind(extractAfter(text, open+1), ">>") + open + 1;
        if isempty(close)
            error("Unclosed template tag")
        end
        close = close(1);
        tag = regexp(extractBetween(text, open+1, close, "Boundaries","exclusive"), "^([\w\/]+)\s+((?:\r|\n|.+)*)$","tokens");
        if isempty(tag)
            error("Invalid template tag")
        end
        parts(end + 1) = {struct("command", tag{1}(1), "args", strrep(tag{1}(2), "$in", "in__"), "pos", open + 2)};
        pos = close + 1;
    end
end
end


function code = compile(text)
tokens = tokenize(text);
stack = struct("type","top","pos",0);

code = "out__ = """";" + newline;
for ii = 1:numel(tokens)
    tok = tokens{ii};

    if isstring(tok)
        code = code + ...
            "out__ = out__ + """ + tok + """;" + newline;
        continue;
    end

    switch tok.command
        case {"in"}
            args = strtrim(strsplit(tok.args, ","));
            for jj = 1:numel(args)
                code = code + args(jj) + " =  $in." + args(jj) + ";" + newline;
            end
        case {"text", "t"}
            code = code + ...
                "out__ = out__ + M__.escapeHTML(" + tok.args + ");" + newline ;
        case {"html", "h"}
            code = code + ...
                "out__ = out__ + (" + tok.args + ");" + newline;
        case {"do"}
            code = code + tok.args + newline;
        case {"if"}
            stack(end + 1) = struct("type", "if", "pos", tok.pos);
            code = code + "if (" + tok.args + ")" + newline;
        case {"elseif"}
            assert(stack(end).type == "if") % TODO: error
            code = code + "elseif (" + tok.args + ")" + newline;
        case {"else"}
            assert(stack(end).type == "if") % TODO: error
            code = code + "else" + newline;
        case {"for"}
            stack(end + 1) = struct("type", "for", "pos", tok.pos);
            code = code + "for " + tok.args + newline;
        case {"end"}
            assert(any(stack(end).type == ["if","for"])) % TODO: error
            code = code + "end" + newline;
            stack(end) = [];    
        otherwise
            code = code + ...
                "out__ = out__ + M__.dispatch(""" + tok.command + """, "+ tok.args + ");" + newline;
    end
end
end

function out__ = evaluate(in,code, mold) %#ok<STOUT> 
M__  = mold;
if ~isempty(fieldnames(mold.Env))
    for f__ = fieldnames(mold.Env)
        eval(f__{1} + " = " + mold.Env.(f__{1}) + ";");
    end
end
in__ = in;
eval(strrep(code,"$in","in__"));
end





