setfenv(1, require'low')

local terra test_math()
	print(floor(5.5), floor([float](5.3f)))
	print(ceil(5.5), ceil([float](5.3f)))
	print(sqrt(2), sqrt([float](2)))
	print('sin', sin(rad(30)), sin([float](rad(30))))
	print('cos', cos(rad(30)), cos([float](rad(30))))
	print('tan', tan(rad(30)), tan([float](rad(30))))
	print('asin', asin(rad(30)), asin([float](rad(30))))
	print('acos', acos(rad(30)), acos([float](rad(30))))
	print('atan', atan(rad(30)), atan([float](rad(30))))
	print('atan2', atan2(1, 1), atan([float](1), [float](1)))
	print('lerp', lerp(([int8])(3), 2, 4, 20, 41.5), lerp(3.15, 2, 4, 20, 40))
end
test_math()

local function test_print()
	local S = struct { x: int; y: int; }
	local f = {} -> {}
	local terra test(): {}
		var a: int[5] = array(1, 2, 3, 4, 5)
		var p: &int = a
		var s = S { 5, 7 }
		print('hello', 'world', 42)
		print([int8](-5), [uint8](5), [int16](-7), [uint16](7))
		print([int32](-2), [uint32](2))
		print([double](3.2e-100), [float](-2.5))
		print(-25LL, 0xffffULL)
		print(p, a, s, f)
	end
	test()
end
test_print()

local cmp = macro(function(t, i, v) return `t[i] <= v end)
local terra test_binsearch()
	var a = arrayof(int, 11, 13, 15)
	var i = 0
	var j = 2
	assert(binsearch(10, a, 0,-1) ==  0)
	assert(binsearch(10, a, 0, 0) ==  0)
	assert(binsearch(11, a, 0, 0) ==  0)
	assert(binsearch(12, a, 0, 0) ==  1)
	assert(binsearch(12, a, 0, 1) ==  1)
	assert(binsearch(13, a, 0, 1) ==  1)
	assert(binsearch(11, a, 0, 1) ==  0)
	assert(binsearch(14, a, 0, 1) ==  2)
	assert(binsearch(10, a, 0, 1) ==  0)
	assert(binsearch(14, a, i, j) ==  2)
	assert(binsearch(12, a, i, j) ==  1)
	assert(binsearch(10, a, i, j) ==  0)
	assert(binsearch(16, a, i, j) ==  3)
end
test_binsearch()

local terra test_freelist()
	var fl: freelist(int32); fl:init()
	var p = fl:alloc()
	assert(fl.items.len == 0)
	fl:release(p)
	assert(fl.items.len == 1)
	var p2 = fl:alloc()
	assert(fl.items.len == 0)
	assert(p == p2)
	fl:release(p2)
	assert(fl.items.len == 1)
	fl:free()
	assert(fl.items.len == 0)
end
test_freelist()

local terra terra_clock()
	return clock()
end
local t0 = terra_clock()
print(clock() - t0)

local function test_publish()
	local public = publish'publish_test'

	local anon = struct {
		c: rawstring;
		d: float;
	};
	anon.metamethods.__typename_ffi = function() return 'ANON' end
	public(anon)
	struct S (public) {
		x: int;
		union {
			a: &&&S;
			union {
				b: &opaque;
				s1: anon;
				s2: anon;
			};
		};
		y: double;
	}
	gettersandsetters(S)

	terra f(x: anon): S end; public(f)
	terra g(x: &opaque, s: cstring, b: bool) end; public(g)

	local bool2 = tuple(bool, bool)
	terra S:f(x: {int, int}, y: {int8, int8, bool2}): {num, num, bool}
		return
			x._0 + x._1,
			y._0 + y._1,
			y._2._0 and y._2._1
	end
	local whoa = {bool, int} -> {bool2, int, S}
	terra S:g(z: whoa): S end

	public:build()

	--print(public:bindingcode())

	local p = require'publish_test'
	local s = ffi.new'S'
	local r = s:f({3, 4}, {5, 6, {true, true}})
	local a, b, c = unpacktuple(r) --using our version of unpacktuple()
	assert(a == 7)
	assert(b == 11)
	assert(c == true)
end
test_publish()
