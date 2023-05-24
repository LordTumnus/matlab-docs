classdef Arguments < myst.Token


    properties
        Properties
        Input = true;
        Output = false; 
        Repeating = false;
    end

    methods
        function setAttributes(this, attr)
            this.Input = attr.Input;
            this.Output = attr.Output;
            this.Repeating = attr.Repeating;
        end
    end

    methods
        function toMarkdown(~)

        end
    end
end