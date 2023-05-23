classdef (Abstract) Token < handle

%     properties (Abstract, Dependent, SetAccess = private)
%         Ref
%     end
%     
    methods (Abstract)
        s = toMarkdown(this)
    end

end