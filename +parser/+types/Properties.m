classdef Properties < parser.types.Token

    properties
        Description
        Mode
        Hidden

        Props parser.types.Property
    end

    methods (Access = ?parser.DocParser)
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
        function setFullName(this, className)
            for ii = 1:numel(this.Props)
                this.Props(ii).setFullName(className);
            end
        end
        function toMarkdown(~)

        end
    end

end