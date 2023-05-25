classdef Function < parser.types.Token

    properties (SetAccess = ?parser.DocParser)
        Name string
        Description string
        Inputs string
        Outputs string
        Arguments parser.types.Arguments
    end

    methods
        function this = Function()
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