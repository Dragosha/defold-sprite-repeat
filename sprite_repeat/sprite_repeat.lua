local M = {}

function M.create(sprite_url, sprite_id, self)

    local atlas_data
    local tex_info
    -- use precashed atlas info if them is available 
    if self and self.atlas_data and self.tex_info then
        atlas_data = self.atlas_data
        tex_info = self.tex_info
    else
        local atlas = go.get(sprite_url, "image")
        atlas_data = resource.get_atlas(atlas)
        tex_info = resource.get_texture_info(atlas_data.texture)
        if self then
            self.atlas_data = atlas_data
            self.tex_info = tex_info
        end
    end
    local tex_w = tex_info.width
    local tex_h = tex_info.height

    -- pprint(atlas_data)
    local animation_data

    local in_sprite_id = sprite_id
    if sprite_id and type(sprite_id) == "string" then
        in_sprite_id = hash(sprite_id)
    end

    local sprite_image_id = in_sprite_id or go.get(sprite_url, "animation")
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
        

        -- local u1 = (position_x) / tex_w
        -- local v1 = (tex_h - (position_y)) / tex_h

        local frame = {
            uv_coord =  vmath.vector4(
                u1 / tex_w,
                (tex_h - v1) / tex_h,
                u2 / tex_w,
                (tex_h - v2) / tex_h
            ),
            w = width,
            h = height,
            uv_rotated = is_rotated and vmath.vector4(0, 1, 0, 0) or vmath.vector4(1, 0, 0, 0)
        }
        table.insert(frames, frame)
    end

    local animation = {
        frames 	= frames,
        width 	= animation_data.width,
        height 	= animation_data.height,
        fps 	= animation_data.fps,
        v 		= vmath.vector4(1, 1, animation_data.width, animation_data.height),
        current_frame = 1,
    }

    -- @param repeat_x 
    -- @param repeat_y
    function animation.animate(repeat_x, repeat_y)

        local frame = animation.frames[1]
        go.set(sprite_url, "uv_coord", frame.uv_coord)
        go.set(sprite_url, "uv_rotated", frame.uv_rotated)
        animation.v.x = repeat_x
        animation.v.y = repeat_y
        animation.v.z = frame.w
        animation.v.w = frame.h
        go.set(sprite_url, "uv_repeat", animation.v)

        if #animation.frames > 1 and animation.fps > 0 then
            animation.handle = 
            timer.delay(1/animation.fps, true, function(self, handle, time_elapsed)
                local frame = animation.frames[animation.current_frame]
                go.set(sprite_url, "uv_coord", frame.uv_coord)
                go.set(sprite_url, "uv_rotated", frame.uv_rotated)
                animation.v.z = frame.w
                animation.v.w = frame.h
                go.set(sprite_url, "uv_repeat", animation.v)
                
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

    return animation
end

return M