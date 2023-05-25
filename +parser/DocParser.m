classdef DocParser

    methods (Access = private)
        function this = DocParser()
        end
    end
    methods (Static)
        function out = parse(name)
            % PARSE parses the class whose name matches the input argument

            % store the full class name (with packages) and its file location
            fileName = which(name);
            % get the mtree of the class
            tree = mtree(fileName, '-file', '-comments', '-cell');
            % if the files contains an error, report it back 
            if(tree.count == 1 && strcmp(tree.kind(), 'ERR'))
                error(tree.string);
            end
            
            % differentiate between class and function
            cnode = tree.mtfind('Kind','CLASSDEF');
            if ~isempty(cnode)
                % parse the class
                out = parser.DocParser.parseClass(cnode);
                % store the full name (packages included)
                out.setFullName(name);
            else
                % parse the function
                fIdx = indices(tree.mtfind('Kind','FUNCTION'));
                out = parser.DocParser.parseFunction(tree.select(fIdx(1)));
                out.FullName = name;
            end
            
        end
    end

    methods (Static, Access = protected)

        function c = parseClass(node)

            % initialize output object
            c = parser.types.Class();

            % parse attributes
            attrs = struct("Hidden", false, "Abstract", false);            
            if ~isempty(node.Cattr)
                attr = parser.DocParser.parseAttributes(node.Cattr.Arg, attrs);
                c.setAttributes(attr);
            end
            
            % parse superclasses
            cexpr = node.Cexpr;
            if node.Cexpr.kind == "LT"
                c.SuperClasses = parser.DocParser.parseSuperClasses(cexpr.Right);
                c.Name = string(cexpr.Left);
            else
                c.Name = string(cexpr);
            end
            line = node.pos2lc(max(cexpr.Tree.endposition));

            % parse comments
            body = node.Body;
            while body.kind == "COMMENT" && body.lineno() == line+1
                c.Description = string(body);
                body = body.Next;
            end

            % find and parse all the property blocks (keyword = "properties")
            props = mtfind(node.Tree, 'Kind', 'PROPERTIES');
            propIdx = props.indices();
            for ii = 1:numel(propIdx)
                p = node.Tree.select(propIdx(ii)); % p is a node in the tree
                propBlocks(ii) = parser.DocParser.parseProperties(p); 
            end
            c.Properties = propBlocks;

            % find and parse all the method blocks (keyword = methods)
            meths = mtfind(node.Tree, 'Kind', 'METHODS');
            methIdx = meths.indices();
            for ii = 1:numel(methIdx)
                m = node.Tree.select(methIdx(ii));
                methBlocks(ii) = parser.DocParser.parseMethods(m);
            end
            c.Methods = methBlocks;
        end

        function propBlock = parseProperties(ptree)
            % parse a property block

            % create a property block object to store its attributes and 
            % properties
            propBlock = parser.types.Properties();

            % parse the attributes
            attrStruct = struct("Description", "", "Hidden", false, ...
                "SetAccess", "public",  "GetAccess", "public", ...
                "Access", "public");

            % parse the the attributes
            attr = ptree.Attr;         
            if attr.count
                attrs = parser.DocParser.parseAttributes(attr.Arg, attrStruct);
                propBlock.setAttributes(attrs);
            end

            % parse the individual properties
            node = ptree.Body;
            propBlock.Props = parser.DocParser.parseProperty(node);

        end

        function methBlock = parseMethods(mnode)
            % parse a method block

            % create the output object
            methBlock = parser.types.Methods();
            attrStruct = struct("Description", "", "Hidden", false, ...
                "Access", "public", "Static", false, "Abstract", false);

             % parse the the attributes
            attr = mnode.Attr;         
            if attr.count
                attrs = parser.DocParser.parseAttributes(attr.Arg, attrStruct);
                methBlock.setAttributes(attrs);
            end
            
            % parse the individual functions
            mtree = mnode.Tree;
            funIdx = indices(mnode.Tree.mtfind('Kind','FUNCTION'));
            for ii = 1:numel(funIdx)
                f = mtree.select(funIdx(ii));
                % skip nested functions 
                if f.trueparent.kind == "METHODS"
                    methBlock.Functions(end + 1) = parser.DocParser.parseFunction(f);
                end
            end
        end


        function s = parseAttributes(node, s)
            % go through the attribute list defined by the first node, and 
            % fill the input struct with the values of those attributes

            % iterate through the nodes
            while(~isempty(node))
                % get left and right sides
                n =  node.Left; 
                v = node.Right;
                % parse name from left
                if(strcmp(n.kind, 'PROPTYPEDECL'))
                    name = string(n.VarName);
                elseif(strcmp(n.kind, 'ATBASE'))
                    name = string(n.Left);
                else
                    name = n.string;
                end
                % parse the value that matches the name -  if the values is 
                % empty, defaults to the original value
                if isfield(s, name)
                    if ~v.isempty()
                        s.(name) = v.tree2str(); % supports metaclasses
                    else
                        s.(name) = true; % default to true if unspecified
                    end
                else
                end
                % next iter
                node = node.Next;
            end
        end


        function propList = parseProperty(node)
            % parse a property from a node

            % create the output
            propList = parser.types.Property.empty();

            while ~isempty(node)

                % parse the comments, if any, and add them to the description of
                % the property node
                description = string.empty();
                lines = [];
                while ~isempty(node) && node.kind == "COMMENT"
                    lines(end + 1) = node.lineno();
                    description(end + 1) = string(node);
                    node = node.Next;
                end
                % return here if after the comment there's nothing
                if isempty(node)
                    return;
                end
                % create the myst property related to this node
                prop = parser.types.Property();

                % get the left and right properties of the node
                n = node.Left;
                v = node.Right;
              
                % parse the property (name, type and size - avoids validation
                % functions), and store the value of the line
                if(strcmp(n.kind, 'PROPTYPEDECL'))
                    prop.Name = string(n.VarName); % name
                    line = n.VarName.lineno();
                    if ~isempty(n.VarType)
                        prop.Class = string(n.VarType); % type
                    end
                    prop.Size = parser.DocParser.parseSize(n.VarDimensions);
                elseif(strcmp(n.kind, 'ATBASE')) % ?
                    prop.Name  = string(n.Left);
                    line = n.Left.lineno();
                else
                    prop.Name  = string(n);
                    line = n.lineno();
                end
                % store the default value if available
                if  ~v.isempty
                    prop.DefaultValue = v.tree2str;
                end

                % store the description
                for ii = 1:numel(description)
                    if lines(ii) == line - numel(description) + ii - 1
                        prop.Description(end + 1) = description(ii);
                    end
                end

                propList(end + 1) = prop;
                node = node.Next;
            end
        end

        function fcn = parseFunction(node)
            % parse a function and return a parser.Function

            % parse name and ios
            fcn = parser.types.Function();
            fcn.Name = string(node.Fname);
            fcn.Inputs = parser.DocParser.parseIO(node.Ins);
            fcn.Outputs = parser.DocParser.parseIO(node.Outs);
            
            % parse body for comments - they need to be next to the function
            % definition
            l = max(node.Fname.lineno, ...
                node.pos2lc(max(node.Ins.Tree.endposition)));
            body = node.Body;
            while ~isempty(body) && body.kind == "COMMENT" && body.lineno == l+1
                fcn.Description(end + 1) = string(body);
                l = l+1;
                body = body.Next;
            end

            % parse the arguments blocks
            if ~isempty(node.Arguments)
                args = parser.DocParser.parseArguments(node.Arguments);
                fcn.Arguments = args;
            end

        end

        function args = parseArguments(node)
            % parse the argument blocks inside a function

            % create the list of argument blocks
            args = parser.types.Arguments.empty();

            while ~isempty(node)
                % create an argument block
                arg = parser.types.Arguments();

                % set the attributes (Input, Output & Repeating)
                attrs = struct("Repeating", false, "Input", true, "Output", false);
                if ~isempty(node.Attr)
                    pAttr = parser.DocParser.parseAttributes(node.Attr.Arg, attrs);
                    arg.setAttributes(pAttr)
                end

                % parse the individual arguments (properties)
                arg.Properties = parser.DocParser.parseArgumentList(node.Body);
                args(end + 1) = arg;
                node = node.Next;
            end
        end

        function argList = parseArgumentList(node)
            % parse the indivudual arguments inside an arguments block (as
            % properties)

            % create the output
            argList = parser.types.Property.empty();

            while ~isempty(node)
                % create the myst property related to this node
                prop = parser.types.Property();

                % parse the comments, if any, and add them to the description of 
                % the property
                lines = [];
                description = string.empty();
                while node.kind == "COMMENT"
                    description(end + 1) = string(node);
                    lines(end + 1) = node.lineno();
                    node = node.Next;
                end
                % return here if after the comment there's nothing
                if isempty(node)
                    return;
                end
                
                if node.kind ~= "ARGUMENT"
                    error("Don't know what's happening in the ARGUMENT")
                end
                % argument name
                prop.Name = string(node.ArgumentValidation.VarName);                
                if ~isempty(node.ArgumentValidation.VarNamedField)
                    prop.Name = prop.Name + ...
                        "." + string(node.ArgumentValidation.VarNamedField);
                end

                % argument type
                if ~isempty(node.ArgumentValidation.VarType)
                    prop.Class = string(node.ArgumentValidation.VarType);
                end
                % argument size
                prop.Size = parser.DocParser.parseSize(node.ArgumentValidation.VarDimensions);
                

                % get also the arg line & store the description
                line = node.ArgumentValidation.VarName.lineno();
                for ii = 1:numel(description)
                    if lines(ii) == line - numel(description) + ii - 1
                        prop.Description(end + 1) = description(ii);
                    end
                end

                % default value
                if ~isempty(node.ArgumentInitialization)
                    prop.DefaultValue = node.ArgumentInitialization.tree2str();
                end
                % save property and move to next
                argList(end + 1) = prop;
                node = node.Next;
            end

        end

        function io = parseIO(node)
            % parse a function input/output

            io = string.empty();

            % iterate through the node
            while ~isempty(node)
                % differenciate unspecified arguments (~)
                if node.kind == "NOT"
                    io(end + 1) = "~";
                else
                    io(end + 1) = string(node);
                end
                % move to next io
                node = node.Next;
            end
        end


        function sz = parseSize(node)
            % parse the size validation of a property/argument

            sz = string.empty();
            % iterate through the nodes, appending the values to a string array
            % if the node is a colon, replace its size value by ":"
            while ~isempty(node)
                if node.kind == "COLON"
                    sz(end + 1) = ":"; 
                else
                    sz(end + 1) = string(node); 
                end
                node = node.Next;
            end
        end

        function s = parseSuperClasses(node)
            % parse a list of superclasses

            % if there's more than one, recursively call this method on the
            % right side of the & expression
            if node.kind == "AND"
                % I am using cells to avoid calling string(string()), which I
                % find weird
                s = {string(node.Left)};
                s = [s parser.DocParser.parseSuperClasses(node.Right)];
            else
                s = {string(node)};
            end
        end
        
    end

end
%#ok<*AGROW> 







