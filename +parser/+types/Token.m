classdef (Abstract) Token < handle

%     properties (Abstract, Dependent, SetAccess = private)
%         Ref
%     end
%     
    properties
        FullName string
    end
    
    methods (Abstract)
        s = toMarkdown(this)
        setFullName(this, name)
    end

end