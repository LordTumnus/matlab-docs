classdef Class < myst.Token
    

    properties (SetAccess = ?myst.DocParser)
        Name string
        Description string
        Abstract
        Hidden
        SuperClasses string
        Properties myst.Properties
        Methods myst.Methods
    end

    methods
        function setAttributes(this, attr)
            this.Abstract = attr.Abstract;
            this.Hidden = attr.Hidden;
        end
    end

    methods
        function md = toMarkdown(this)
            md = "";
        end
    end
end