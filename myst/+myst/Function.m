classdef Function < myst.Token

    properties (SetAccess = ?myst.DocParser)
        Name 
        Description string
        Inputs string
        Outputs string
        Arguments myst.Arguments
    end

    methods
        function this = Function()
        end

    end
    methods 
        function s = toMarkdown(this)
            
        end
    end
    
end