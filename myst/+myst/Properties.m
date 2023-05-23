classdef Properties < myst.Token

    properties
        Description
        Mode
        Hidden

        Props myst.Property
    end

    methods (Access = ?myst.DocParser)
        function setAttributes(this, attr)
            this.Hidden = attr.Hidden;
            this.Description = attr.Description;
            if attr.Access == "public" && attr.GetAccess == "public" && attr.SetAccess == "public"
                this.Mode = "public";
            elseif attr.GetAccess == "public" && attr.SetAccess ~= "public" 
                this.Mode = "read-only";
            else
                this.Mode = "other";
            end
        end
    end
    methods
        function toMarkdown(~)

        end
    end

end