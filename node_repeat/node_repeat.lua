local M = {}

-- @param node_or_string -- name of node
-- @param animation_id -- string or id, if [nil] than will be taken from get_flipbook (node)
-- @param atlas_path -- path to get atlas info through resource.get_atlas
function M.create(node_or_string, animation_id, atlas_path)

    local node = type(node_or_string) == "string" and gui.get_node(node_or_string) or node_or_string

    assert(atlas_path, "Need an atlas path resource")
    local atlas_data = resource.get_atlas(atlas_path)
    local tex_info = resource.get_texture_info(atlas_data.texture)
    local tex_w = tex_info.width
    local tex_h = tex_info.height

    local animation_data

    local in_animation_id = animation_id
    if animation_id and type(animation_id) == "string" then
        in_animation_id = hash(animation_id)
    end

    local sprite_image_id = in_animation_id or gui.get_flipbook(node)
    for i, animation in ipairs(atlas_data.animations) do
        if hash(animation.id) == sprite_image_id then
            animation_data = animation
            -- print(i, animation.id, animation.width, animation.height, animation.frame_start)
            break
        end
    end
    assert(animation_data, "Unable to find image " .. sprite_image_id)

    local frames = {}
    for index = animation_data.frame_start, animation_data.frame_end - 1 do

        local uvs = atlas_data.geometries[index].uvs
        assert(#uvs == 8, "Sprite trim mode should be disabled for the images.")

        --   UV texture coordinates
        --   1
        --   ^ V
        --   |
        --   |
        --   |       U
        --   0-------> 1

        -- uvs = {
        -- 0,     0,
        -- 0,     height,
        -- width, height,
        -- width, 0
        -- },
        -- geometries.indices = {0 (1,2),  1(3,4),  2(5,6),  0(1,2),  2(5,6),  3(7,8)}
        --   1------2
        --   |    / |
        --   | A /  |
        --   |  / B |
        --   | /    | 
        --   0------3

        local width = uvs[5] - uvs[1]
        local height = uvs[2] - uvs[6]       
        local u1 = uvs[1]
        local v1 = uvs[6]
        local u2 = uvs[5]
        local v2 = uvs[2]
        local is_rotated = false
        -- pprint(atlas_data.geometries[index])
        if height < 0 then
            -- In case the atlas has clockwise rotated sprite.
            --   0------1
            --   |\  A  |
            --   | \    |
            --   |  \   |
            --   | B  \ | 
            --   3------2

            height = uvs[5] - uvs[1]
            width = uvs[6] - uvs[2]
            -- print("rotated", width, height)
            is_rotated = true
        end
        
        local frame = {
            uv_coord =  vmath.vector4(
                u1 / tex_w,
                (tex_h - v1) / tex_h,
                u2 / tex_w,
                (tex_h - v2) / tex_h
            ),
            w = width,
            h = height,
            -- For some reason uv_rotated info isn't needed for the gui shader against sprite shader. why? :-\
            uv_rotated = is_rotated and vmath.vector4(0, 1, 0, 0) or vmath.vector4(1, 0, 0, 0)
        }
        table.insert(frames, frame)
    end

    local animation = {
        frames 	= frames,
        width   = animation_data.width,
        height 	= animation_data.height,
        fps     = animation_data.fps,
        v       = vmath.vector4(1, 1, animation_data.width, animation_data.height),
        current_frame = 1,
        node    = node,
    }

    -- Start our repeat shader work
    -- @param repeat_x -- X factor
    -- @param repeat_y -- Y factor
    function animation.animate(repeat_x, repeat_y)

        local frame = animation.frames[1]
        gui.set(node, "uv_coord", frame.uv_coord)
        -- gui.set(node, "uv_rotated", frame.uv_rotated)
        animation.v.x = repeat_x
        animation.v.y = repeat_y
        animation.v.z = frame.w
        animation.v.w = frame.h
        gui.set(node, "uv_repeat", animation.v)

        if #animation.frames > 1 and animation.fps > 0 then
            animation.handle = 
            timer.delay(1/animation.fps, true, function(self, handle, time_elapsed)
                local frame = animation.frames[animation.current_frame]
                gui.set(node, "uv_coord", frame.uv_coord)
                -- gui.set(node, "uv_rotated", frame.uv_rotated)
                animation.v.z = frame.w
                animation.v.w = frame.h
                gui.set(node, "uv_repeat", animation.v)
                
                animation.current_frame = animation.current_frame + 1
                if animation.current_frame > #animation.frames then
                    animation.current_frame = 1
                end
            end)
        end
    end

    function animation.stop()
        if animation.handle then
            timer.cancel(animation.handle)
            animation.handle = nil
        end
    end

    -- Update repeat factor values
    -- @param repeat_x 
    -- @param repeat_y
    function animation.update(repeat_x, repeat_y)
        if repeat_x then animation.v.x = repeat_x end
        if repeat_y then animation.v.y = repeat_y end
        gui.set(node, "uv_repeat", animation.v)
    end

    return animation
end


M.x_ratio = 1
M.y_ratio = 1

function M.get_screen_aspect_ratio()
    local window_x, window_y = window.get_size()
    local stretch_x = window_x / gui.get_width()
    local stretch_y = window_y / gui.get_height()

    M.x_ratio = stretch_x / math.min(stretch_x, stretch_y)
    M.y_ratio = stretch_y / math.min(stretch_x, stretch_y)

    return  M.x_ratio, M.y_ratio
end

return M