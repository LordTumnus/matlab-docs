classdef Class < parser.types.Token
    

    properties (SetAccess = ?parser.DocParser)
        Name string
        Description string
        Abstract
        Hidden
        SuperClasses string
        Properties parser.types.Properties
        Methods parser.types.Methods
    end

    methods
        function setAttributes(this, attr)
            this.Abstract = attr.Abstract;
            this.Hidden = attr.Hidden;
        end
    end

    methods
        function setFullName(this, name)
            this.FullName = name;
            for ii = 1:numel(this.Methods)
                this.Methods(ii).setFullName(name);
            end
            for ii = 1:numel(this.Properties)
                this.Properties(ii).setFullName(name);
            end
        end
        function md = toMarkdown(this)
            md = "";
        end
    end
end