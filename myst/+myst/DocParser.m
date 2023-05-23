classdef DocParser < handle

    properties
        Name (1,1) string
        FileName (1,1) string
        Tree (1,1) % mtree
    end

    methods 
        function parse(this, name)
            % PARSE parses the class whose name matches the input argument

            % store the full class name (with packages) and its file location
            this.Name = name;
            this.FileName = which(name);
            % get the mtree of the class
            this.Tree = mtree(this.FileName, '-file', '-comments');
            % if the files contains an error, report it back 
            if(this.Tree.count == 1 && strcmp(obj.Tree.kind(), 'ERR'))
                error(this.Tree.string);
            end
            % parse the class
            this.parseClass()
        end
    end

    methods 

        function parseClass(this)

            % find and parse all the property blocks (keyword = "properties")
            props = mtfind(this.Tree, 'Kind', 'PROPERTIES');
            propIdx = props.indices();
            for ii = 1:numel(propIdx)
                p = this.Tree.select(propIdx(ii)); % p is a node in the tree
                propBlocks(ii) = this.parseProperties(p);
            end

            % find and parse all the method blocks (keyword = methods)
            meths = mtfind(this.Tree, 'Kind', 'METHODS');
            methIdx = meths.indices();
            for ii = 1:numel(methIdx)
                methBlocks(ii) = this.parseMethods(this.Tree.select(methIdx(ii)));
            end
        end
    end


    methods (Static)

        function propBlock = parseProperties(ptree)
            % parse a property block

            % create a property block object to store its attributes and 
            % properties
            propBlock = myst.Properties();

            % parse the attributes
            attrStruct = struct("Description", "", "Hidden", false, ...
                "SetAccess", "public",  "GetAccess", "public", ...
                "Access", "public");

            % parse the the attributes
            attr = ptree.Attr;         
            if attr.count
                attrs = myst.DocParser.parseAttributes(attr.Arg, attrStruct);
                propBlock.setAttributes(attrs);
            end

            % parse the individual properties
            node = ptree.Body;
            propBlock.Props = myst.DocParser.parseProperty(node);

        end

        function methBlock = parseMethods(mtree)

            methBlock = myst.Methods();
            attrStruct = struct("Description", "", "Hidden", false, ...
                "Access", "public", "Static", false, "Abstract", false);

             % parse the the attributes
            attr = mtree.Attr;         
            if attr.count
                attrs = myst.DocParser.getAttributes(attr.Arg, attrStruct);
                methBlock.setAttributes(attrs);
            end
            
            % parse the individual functions
            current = mtree.Tree.mtfind('Kind','FUNCTION');

            while ~isempty(current)

                methBlock.Functions(end + 1) = myst.Function();

                methBlock.Functions(end).Name = string(current.Fname);
                if ~isempty(current.Ins)
                    in = current.Ins;
                    while ~isempty(in)
                        if in.kind == "NOT"
                            methBlock.Functions(end).Inputs(end + 1) = "~";
                        else
                            methBlock.Functions(end).Inputs(end + 1) = string(in);
                        end
                        in = in.Next;
                    end
                end
                if ~isempty(current.Outs)
                    out = current.Outs;
                    while ~isempty(out)
                        if out.kind == "NOT"
                            methBlock.Functions(end).Outputs(end + 1) = "~";
                        else
                            methBlock.Functions(end).Outputs(end + 1) = string(out);
                        end
                        out = out.Next;
                    end
                end
                
                body = current.Body;
                while ~isempty(body) && body.kind == "COMMENT"
                    methBlock.Functions(end).Description(end + 1) = string(body);
                    body = body.Next;
                end

                if ~isempty(current.Arguments)
                    currarg = current.Arguments.Body;
                    newarg = true;

                    while ~isempty(currarg)
                        if newarg
                            methBlock.Functions(end).Arguments(end + 1) = myst.Property();
                            newarg = false;
                        end

                        if currarg.kind == "COMMENT"
                            methBlock.Functions(end).Arguments(end).Description(end + 1) = string(currarg);
                        elseif currarg.kind == "ARGUMENT"
                            methBlock.Functions(end).Arguments(end).Name = string(currarg.ArgumentValidation.VarName);

                            if ~isempty(currarg.ArgumentValidation.VarType)
                                methBlock.Functions(end).Arguments(end).Class = string(currarg.ArgumentValidation.VarType);
                            end
                            if ~isempty(currarg.ArgumentValidation.VarDimensions)
                                dim = currarg.ArgumentValidation.VarDimensions;
                                while ~isempty(dim)
                                     if dim.kind == "COLON"
                                         methBlock.Functions(end).Arguments(end).Size(end + 1) = ":";
                                     else
                                         methBlock.Functions(end).Arguments(end).Size(end + 1) = string(dim);
                                     end
                                     dim = dim.Next;
                                end
                            end

                            if ~isempty(currarg.ArgumentInitialization)
                                methBlock.Functions(end).Arguments(end).DefaultValue = currarg.ArgumentInitialization.tree2str();
                            end
                            newarg = true;
                        end
                        currarg = currarg.Next;
                    end

                end
                current = current.Next;

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
                if isfield(s, name) && ~v.isempty
                    s.(name) = v.tree2str(); % supports metaclasses
                end
                % next iter
                node = node.Next;
            end
        end


        function propList = parseProperty(node)
            % parse a property from a node

            % create the output
            propList = myst.Property.empty();

            while ~isempty(node)
                % create the myst property related to this node
                prop = myst.Property();

                % parse the comments, if any, and add them to the description of the
                % property node
                while node.kind == "COMMENT"
                    prop.Description(end + 1) = string(node);
                    node = node.Next;
                end

                % get the left and right properties of the node
                n = node.Left;
                v = node.Right;

                % parse the property (name, type and size - avoids validation
                % functions)
                if(strcmp(n.kind, 'PROPTYPEDECL'))
                    prop.Name = string(n.VarName); % name
                    if ~isempty(n.VarType)
                        prop.Class = string(n.VarType); % type
                    end
                    prop.Size = myst.DocParser.parseSize(n.VarDimensions);
                elseif(strcmp(n.kind, 'ATBASE')) % ?
                    prop.Name  = string(n.Left);
                else
                    prop.Name  = string(n);
                end
                % store the default value if available
                if  ~v.isempty
                    prop.DefaultValue = v.tree2str;
                end
                propList(end + 1) = prop;
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
        
    end

end
%#ok<*AGROW> 







