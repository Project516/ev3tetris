#!/usr/bin/env lua5.3
-- SPDX-License-Identifier: MIT
-- Copyright: 2018 David Lechner <david@lechnology.com>
-- File: netris-bot.lua

-- This is a bot program for controlling netris. It reads button presses on
-- LEGO MINDSTORMS EV3 and translates them to messages that netris understands.
--
-- Prerequisties:
--      # run this on the EV3
--      sudo apt update
--      sudo apt install netris lua-posix
--
-- Usage:
--      # run this on the EV3
--      brickrun -- /usr/games/netris -C -r 'lua5.3 netris-bot.lua'
--

-- Linux event types
local EV_KEY = 0x01

-- Linux key codes
local KEY_ENTER = 28
local KEY_UP = 103
local KEY_LEFT = 105
local KEY_RIGHT = 106
local KEY_DOWN = 108

local fileno = require "posix.stdio".fileno
local poll = require "posix.poll".poll

function debug_print(message)
    io.stderr:write(message .. '\n')
end

function read_msg()
    return io.stdin:read('*l')
end

function write_msg(msg)
    io.stdout:write(msg .. '\n')
    io.stdout:flush()
end

-- path to event device for EV3 buttons (mainline kernel/ev3dev-stretch)
local evdev = assert(io.open('/dev/input/by-path/platform-gpio_keys-event', 'rb'))

local evdev_fd = fileno(evdev)
local stdin_fd = fileno(io.stdin)

local fds = {
    [evdev_fd] = {events={IN=true}},
    [stdin_fd] = {events={IN=true}},
}

-- ID (serial number) of current piece
local current_piece = ''

write_msg('Version 1')

while true
do
    poll(fds, -1)

    if fds[evdev_fd].revents.IN then
        local event = evdev:read(16)

        -- skiping timestamp (first 8 bytes)
        local type, code, value = string.unpack('I2I2i4', event, 9)

        -- debug_print('type: ' .. type .. ' code: ' .. code .. ' value: ' .. value)

        -- we only care about key events
        if type == EV_KEY then
            -- we only care about key press, not rease
            if value == 1 then
                if code == KEY_UP then
                    write_msg('Rotate ' .. current_piece)
                elseif code == KEY_LEFT then
                    write_msg('Left ' .. current_piece)
                elseif code == KEY_RIGHT then
                    write_msg('Right ' .. current_piece)
                elseif code == KEY_DOWN then
                    write_msg('Drop ' .. current_piece)
                end
            end
        end
    end

    if fds[stdin_fd].revents.IN then
        local msg = read_msg()
        local iter = msg:gmatch('%S+')
        local cmd = iter()
        if cmd == 'Exit' then
            os.exit(0)
        elseif cmd == 'NewPiece' then
            current_piece = iter()
        end
    end
end
