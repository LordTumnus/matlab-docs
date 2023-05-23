classdef Methods < myst.Token

    properties (SetAccess = ?myst.DocParser)
        Abstract = false;
        Mode = "public";
        Hidden = false;
        Static = false;
        Description;

        Functions myst.Function
    end

    methods
        function this = Methods()
        end
    end
    methods (Access = ?myst.DocParser)
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
        function s = toMarkdown(this)
            
        end
    end
    
end