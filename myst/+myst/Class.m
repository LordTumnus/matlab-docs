classdef Class < myst.Token
    

    properties (SetAccess = ?myst.Parser)
        Name string
        Description string
        DetailedDescription string
        Abstract
        SuperClasses myst.Class
        Properties myst.Property
        Methods myst.Method
        GeneratesDoc logical = true;
    end

    methods 
        function this = Class(name)
            this.Name = name;
        end

        function r = getTypeReference(this)
            if this.GeneratesDoc
                r = sprintf("[%s]{#%s .type}", this.Name, this.Name);
            else
                r = sprintf("[%s]{.type}", this.Name);
            end
        end
    end

    methods
        function s = generateDocument(this, folder) %#ok<INUSD>
            if this.GeneratesDoc
                s = this.toMarkdown();
                % [TODO]: generate markdown file in folder
            end
        end
    
        function md = toMarkdown(this)
            md = "";
        end
    end
end