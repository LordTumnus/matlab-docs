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
            % parse the components
            this.parseComponents()
        end
    end

    methods 

        function parseComponents(this)
            % parse the properties
            props = mtfind(this.Tree, 'Kind', 'PROPERTIES');
            propIdx = props.indices();
            for ii = 1:numel(propIdx)
                propBlocks(ii) = this.parseProperties(this.Tree.select(propIdx(ii)).Tree);
            end


            meths = mtfind(this.Tree, 'Kind', 'METHODS');
            methIdx = meths.indices();
            for ii = 1:numel(methIdx)
                methBlocks(ii) = this.parseMethods(this.Tree.select(methIdx(ii)).Tree);
            end
        end
    end


    methods (Static)

        function propBlock = parseProperties(ptree)
            % parse a property block

            propBlock = myst.Properties();
            attrStruct = struct("Description", "", "Hidden", false, ...
                "SetAccess", "public",  "GetAccess", "public", "Access", "public");

            % parse the the attributes
            attr = ptree.mtfind('Kind', 'ATTRIBUTES');         
            if attr.count
                attrs = myst.DocParser.getAttributes(attr.Arg, attrStruct);
                propBlock.setAttributes(attrs);
            end

            % parse the individual properties
            current = ptree.Body;
            newprop = true;

            while ~isempty(current)
                if newprop
                    propBlock.Props(end + 1) = myst.Property();
                    newprop = false;
                end

                if current.kind == "COMMENT"
                    propBlock.Props(end).Description(end + 1) = string(current);
                else
                    n = current.Left;
                    v = current.Right;
                    if(strcmp(n.kind, 'PROPTYPEDECL'))
                        propBlock.Props(end).Name = string(n.VarName);
                        if n.VarType.count
                            propBlock.Props(end).Class = string(n.VarType);
                        end
                        if n.VarDimensions.count
                            dim = n.VarDimensions;
                            while ~isempty(dim)
                                if dim.kind == "COLON"
                                    propBlock.Props(end).Size(end + 1) = ":";
                                else
                                    propBlock.Props(end).Size(end + 1) = string(dim);
                                end
                                dim = dim.Next;
                            end
                        end
                    elseif(strcmp(n.kind, 'ATBASE'))
                        propBlock.Props(end).Name  = string(n.Left);
                    else
                        propBlock.Props(end).Name  = n.string;
                    end
                    if  ~v.isempty
                        propBlock.Props(end).DefaultValue = v.tree2str;
                    end
                    newprop = true;
                end
                current = current.Next;
            end



        end

        function methBlock = parseMethods(mtree)

            methBlock = myst.Methods();
            attrStruct = struct("Description", "", "Hidden", false, ...
                "Access", "public", "Static", false, "Abstract", false);

             % parse the the attributes
            attr = mtree.mtfind('Kind', 'ATTRIBUTES');         
            if attr.count
                attrs = myst.DocParser.getAttributes(attr.Arg, attrStruct);
                methBlock.setAttributes(attrs);
            end
            

            % parse the individual functions
            current = mtree.Body.mtfind('Kind','FUNCTION');

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


        function s = getAttributes(tree, s)
            current = tree;
            while(~isempty(current))
                n =  current.Left;
                v = current.Right;
                if(strcmp(n.kind, 'PROPTYPEDECL'))
                    name = string(n.VarName);
                elseif(strcmp(n.kind, 'ATBASE'))
                    name = string(n.Left);
                else
                    name = n.string;
                end
                if isfield(s, name) && ~v.isempty
                    s.(name) = v.tree2str();
                end
                current = current.Next;
            end
        end
       
    end


end






