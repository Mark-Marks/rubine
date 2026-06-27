--# selene: allow(undefined_variable)

export type function writeable(t: type): type
    if t.tag ~= "table" then
        return t
    end

    for key, rw in t:properties() do
        const prop = rw.read or rw.write
        if not prop then
            continue
        end

        t:setproperty(key, prop)
    end

    const indexer = t:indexer()
    const result = indexer and (indexer.readresult or indexer.writeresult)
    if indexer and result then
        t:setindexer(indexer.index, result)
    end

    return t
end

export type function strip_component(component: type): type
    if component.tag ~= "table" then
        return component
    end

    for key, rw in component:properties() do
        if key ~= types.singleton("__T") then
            continue
        end

        const prop = rw.read or rw.write
        if prop then
            return prop
        end
    end

    return component
end

export type function strip_components(pack: type): type
    if pack.tag ~= "function" then
        return pack
    end

    const params = pack:parameters()
    const head = params.head
    if not head then
        return pack
    end

    local updated_head = {}
    for _, param in head do
        table.insert(updated_head, strip_component(param) :: type)
    end

    return types.newfunction { head = updated_head }
end

export type function any_of(pack: type): type
    if pack.tag ~= "function" then
        return pack
    end

    const params = pack:parameters()
    const head = params.head
    if not head then
        return types.any
    end

    return types.unionof(unpack(head))
end

export type function is_one_of(ty: type, allowed_pack: type)
    if allowed_pack.tag ~= "union" then
        if ty == allowed_pack then
            return ty
        end

        return types.never
    end

    const allowed_types = allowed_pack:components()
    for _, allowed_type in allowed_types do
        if
            allowed_type.tag == "union"
            and is_one_of(ty, allowed_type) ~= types.never
        then
            return ty
        end

        if ty == allowed_type or allowed_type.tag == "any" then
            return ty
        end
    end

    return types.never
end

-- selene: allow(unused_variable)
export type function ecs_field_return(
    component: type,
    query_cts: type,
    singleton_cts: type
): type
    if is_one_of(component, query_cts) ~= types.never then
        return types.newtable(nil, {
            index = types.number,
            readresult = strip_component(component) :: type,
            writeresult = types.never,
        })
    end

    return strip_component(component) :: type
end

export type Pack<T...> = (T...) -> ()

return nil
