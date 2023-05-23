classdef Property < myst.Token

    properties (SetAccess = ?myst.DocParser)
        Name string
        Description string
        Class string
        Size string
        DefaultValue string
    end

    methods
        function this = Property()
        end
    end
    methods 
        function s = toMarkdown(this)
            s = "**" + this.Name + "**";
            if isempty(this.Class)
                s = s + ": [any]{.type}";
            else
                s = s + ": " + this.Class.getTypeReference();
            end

            if ~isempty(this.DefaultValue)
                s = s + " = " + this.DefaultValue;
            end

           s = s + newline + ": " + strtrim(this.DetailedDescription);

        end
    end
end