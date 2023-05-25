classdef Methods < parser.types.Token

    properties (SetAccess = ?parser.DocParser)
        Abstract = false;
        Mode = "public";
        Hidden = false;
        Static = false;
        Description;

        Functions parser.types.Function
    end

    methods
        function this = Methods()
        end
    end
    methods (Access = ?parser.DocParser)
        function setAttributes(this, attr)
            this.Hidden = attr.Hidden;
            this.Static = attr.Static;
            if attr.Access == "public"
                this.Mode = "public";
            else
                this.Mode = "other";
            end
        end
    end

    methods 

        function setFullName(this, className)
            for ii = 1:numel(this.Functions)
                this.Functions(ii).setFullName(className);
            end
        end
        function s = toMarkdown(this)
            
        end
    end
    
end