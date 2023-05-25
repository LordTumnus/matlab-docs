classdef Property < parser.types.Token

    properties (SetAccess = ?parser.DocParser)
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
        function setFullName(this, className)
            this.FullName = this.Name + "." + className;
        end
        function s = toMarkdown(this)
            
        end
    end
end