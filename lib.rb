def reload
	load './lib.rb'
end

@goalStop = 0.1

def hsv_to_rgb(h, s, v)
  h_i = (h*6).to_i
  f = h*6 - h_i
  p = v * (1 - s)
  q = v * (1 - f*s)
  t = v * (1 - (1 - f) * s)
  r, g, b = v, t, p if h_i==0
  r, g, b = q, v, p if h_i==1
  r, g, b = p, v, t if h_i==2
  r, g, b = p, q, v if h_i==3
  r, g, b = t, p, v if h_i==4
  r, g, b = v, p, q if h_i==5
  [(r*255).to_i, (g*255).to_i, (b*255).to_i]
end

def rgb_to_hex(r, g, b)
	r.to_s(16).rjust(2, "0") + g.to_s(16).rjust(2, "0") + b.to_s(16).rjust(2, "0")
end

def bans 
	@goals + [@pos]
end

def rndPos n = 100
	(1 + Random.rand(n)) * 6 - 1 + 2 * Random.rand(2)
end

def rndGoal 
	x = 5
	while rand > @goalStop || bans.include?(x)
		x = nextPos x
	end
	x
end

@pos = 5
@fail = 0.2
@life = 100
@goals = []
#3.times { @goals << rndGoal }
@score = 0

def set x
	@pos = x
end

def up x, n = 1
	x.up n
end

def scale(x) if (x > 0) then x ** 0.2 else -((-x) ** 0.2) end end

def comp(x, y, p) x ** p - y ** p end

$cs = 15

def locs
	Enumerator.new do |y|
		x = 6
		loop {
			y << x-1
			y << x+1
			x += 6
		}
	end
end

class Numeric
	def forward() self % 2 == 0 ? (self/2).forward : self end
	def left() (3*self-1).forward	end
	def right()	(3*self+1).forward end
	def lr() [left, right] end

  def up n = 1
  	x = self
		n.times { x = x.lr.max }
		x
  end

	def down n = 1
		x = self
		n.times { x = x.lr.min }
		x
	end

  def u(n = 1) up n end
  def d(n = 1) down n end
	def du() [d, u] end
	def ud() [u, d] end

	def jump 
		x = self * 3
		if x % 4 == 1 then x -= 1; else x += 1; end
    n = 0
    while (x % 2 == 0) do x /= 2; n += 1; end
    n-1
  end

	def prevs
		x = self
		Enumerator.new do |y|
			loop {
				x *= 2
				y << (x % 3 == 1 ? (x-1)/3 : (x+1)/3)
			}
		end
	end

	def prevsf() prevs.lazy.select{|x| x%3 != 0} end

	def prev(n = 1) prevsf.drop(n-1).first end

	def back n = 1
		x = self
		n.times do x = x.prev end
	  x
	end
	def b() back end

	def nextPos() self % 3 == 1 ? self + 4 : self + 2 end

  def zoom() 60 end
	def stage() Math.log(self, 2) % 1 end
	def ray() Math.log(self, 1.5) % 1 end
	def rayd() ray * 360 end
	def angle() ray * 2 * Math::PI end
	def a() phase * 360 % 360 end
  def radius() zoom * self ** 0.5 end
  def x() radius * Math.cos(angle) end
  def y() radius * Math.sin(angle) end
  def p() [x.round, y.round] end

  def as(x = 0, y = 0, start = 5) self - base(x, y, start) end
  def s(x = 0, y = 0) Math.log(self/base(x, y)) end
  def base(x = 0, y = 0, start = 5) start * 1.5**(x+y) / 2**y end

  def rhombusClassic() u.d == d.u end
  def rc() rhombusClassic end
  def rhombusDrop() u.d == d.d end
  def rd() rhombusDrop end
  def rhombus() rhombusClassic || rhombusDrop end
  def rh() rhombus end
  def royal() self % 9 == 4 || self % 9 == 5 end
  def rhombusConjecture() rhombus || u.d.royal end
  def supportDecreasingConjecture() !(jump == 1 && u.u.d == d.u.u && u.d != d.u) end
  def kingKingRhombusConjecture() !(royal && back.royal && back(2).u.d != self) end

  def hue(x, y) (1.0/3 - s(x, y) * $cs) % 1 end
  def mixedHue(x, y, d2, x2, y2, k = 0.5) (1.0/3 - ((1-k)*s(x, y) + k*d2.s(x2, y2)) * $cs) % 1 end
  def color(x, y) rgb_to_hex(*hsv_to_rgb(hue(x, y), 0.2, 1)) end
  def mixedColor(x, y, d2, x2, y2) rgb_to_hex(*hsv_to_rgb(mixedHue(x, y, d2, x2, y2), 0.2, 1)) end
  def lineColor(x, y) rgb_to_hex(*hsv_to_rgb(hue(x, y), 1, 1)) end
  def c(x, y) color(x, y) end
  def mc(x, y, d2, x2, y2) mixedColor(x, y, d2, x2, y2) end
  def l(x, y) lineColor(x, y) end

  def growth
  	x = self
  	s = ""
  	10.times do
  		print "  "
  		if x % 4 == 1
  			print "-"
  			x = (x * 3 - 1) / 2
  		else 
  			print "+"
  			x = (x * 3 + 1) /2
  		end
  	end
  	s
  end

  def bfs target, edges = :du, maxSteps = 100000
  	visited = []
  	from = []
    queue = Queue.new
    queue << self
    visited[self] = 0
    while visited[target] == nil && maxSteps > 0 do
      u = queue.pop
      u.send(edges).each do |v| 
      	if visited[v] == nil || visited[v] == visited[u]+1 && from[v] > u
      		visited[v] = visited[u]+1
      		from[v] = u
      		queue << v
      	end
      end
      maxSteps -= 1
    end
    return nil if visited[target] == nil 
    path = [target]
    while target != self do
    	target = from[target]
    	path.unshift target
    end
    return path
  end

  def wayUp from = 5
  	x = self
  	path = [x]
  	while x != from do
  		y = x.back

  		x = y
  		path.unshift x
  	end
  	return path
  end

  def goUp x, to

		x.d == 1 ||

		# works up to 80

		[101].include?(x) && (to & [71, 53]).any? || 
		# jump from 95 to 71, but 101 to 19

		[31, 47, 71, 107].include?(x) && (to & [91]).any? || 
		# jump from 121 to 91, but 107 to 5
		[31, 47, 71, 107].include?(x) && (to & [157]).any? || 
		# also 91 shotcutted into 157

		[139].include?(x) && (to & [59]).any? ||
		# jump from 157 to 59, but 139 to 13

		[149].include?(x) && (to & [125, 47, 35]).any? ||
		# jump from 167 to 125, but 149 to 7

		[235].include?(x) && (to & [199]).any? ||
		# jump from 265 to 199, but 235 to 11
		[235].include?(x) && (to & [253, 95]).any? ||
		# also 199 shortcutted into 253 and 95

		[245].include?(x) && (to & [103]).any? ||
		# jump from 275 to 103, but 245 to 23
		[245].include?(x) && (to & [157]).any? ||
		# also 103 shortcutted into 157

		[185, 277].include?(x) && (to & [233]).any? ||
		# jump from 311 to 233, but 277 to 13

		[133, 199, 299].include?(x) && (to & [253, 95]).any? || 
		[299].include?(x) && (to & [71, 53]).any? || 
		# jump from 337 to 253, but 299 to 7

		[5, 7, 11, 17, 25, 37, 41, 61, 91, 103, 155, 131, 197, 221, 331, 373].include?(x) && (to & [157]).any? ||
		# jump from 419 to 157, but 373 to 35

		[91, 103, 155, 175, 263, 395, 107].include?(x) && (to & [167]).any? ||
		# jump from 445 to 167, but 395 to 37; also 107 shortcutted into 91

		[49, 73, 109, 163, 245, 275, 413, 619, 697, 1045].include?(x) && (to & [881, 557, 209]).any? ||
		# jump from 1175 to 881, but 1045 to 49

		[587, 661].include?(x) && (to & [557, 209]).any? ||
		# jump from 743 to 557, but 661 to 31

		false  	
  end

  def wayDown to = 5
  	to = [to] if to.class != Array
  	x = self
  	path = [x]
  	loop do
  		break if to.last == x
  		y = x.d
  		if 
  			goUp x, to
  		then
  		  y = x.u
  		else
  			break if to.include?(x)
  		end
  		x = y
  		path << x
  		if path.length > 100
  			print "wayDown(#{to}) path: #{path}"
  			return path
  		end
  	end
  	return path  	
  end

  def route target
  	line = target.wayUp
  	downPart = wayDown line
  	return downPart + target.wayUp(downPart.last).drop(1)
  end
end

def pgrowth
	x = 1
	128.times do 
		x.growth
		print "\n"
		x += 2
	end
end

def check conjecture, n = 100000
	x = 5
	sat = []
	n.times do 
		if x.send(conjecture)
			sat << x
		else
			print "#{x}: conjecture FAILED\n"
		end
		x = x.nextPos
	end
	print "conjecture satisfied for #{sat.size} numbers\n"
end

def pass x, y, z
	x.bfs(y).length + y.bfs(z).length - 1 - x.bfs(z).length
end

def checkRoute x, y
	bfs = x.bfs(y)
	route = x.route(y)
	if bfs.length != route.length && bfs[1] != route[1]
		print "#{x}.bfs(#{y}): #{bfs}\n"
	end
end

def checkRoutes n, m
	locs.first(n).each do |x|
		print "check routes from #{x}\n"
		locs.first(m).each do |y|
			checkRoute x, y
		end
	end
end

def tree x, n = 1, used = []
	queue = [[x,0]]
	lastDepth = 0
	result = []
	while queue.count > 0
		to = queue.shift
		x = to[0]
		depth = to[1]
		if used.include?(x) || depth >= n
			next
		end
		used << x
		d = x.d
		u = x.u
		result << "" if depth != lastDepth 
		lastDepth = depth
		result << "#{x} -> #{d}, #{u}"
		queue << [d, depth+1] << [u, depth+1]
	end
	result.join("\n")
end

def ptree x, n = 1
	print tree(x, n)
	print "\n"
end

def children x, n = 1
	return [left(x), right(x)] if n == 1
	return (children(left(x), n-1) + children(right(x), n-1)).uniq
end

# def rhombus x, n = 1
# 	children(x, n).map{|i| children(i,n)}.collect

def cur 
	print "[#{@life}] #{tree(@pos)} (#{@goals.join ', '})\n"
	nil
end

cur

def move x
	return if (left(@pos) != x && right(@pos) != x)
	old = @pos
	good = x
	bad = left(@pos) + right(@pos) - x
	set good
	if rand < @fail
		set bad
		print "WHOOPS\n"
	end
	@life -= 1
	if @pos == 1
		set old if @life > 30
		@life -= 30
		print "BANG\n"
	end
	if @life <= 0
		print "YOU DEAD\n"
	end
	if @goals.include? @pos
		@life += 20
		@goals -= [@pos]
		@goals << rndGoal
	end
	cur
end

def chain x, n = 10
	(0..n).map{|i| up x, i}
end

def prev x, n = 1
	x *= (2**n)
	x % 3 == 1 ? (x-1)/3 : (x+1)/3
end

def backs x, n = 10, filtered = true
	(1..n).map{|i| prev x, i}.select{|y| y%3 != 0}
end

def back x, n = 1
	backs(x, 2*n+3)[n-1]
end

def traceBack x, n = 1
  (1..n).map{|i| x; x = back x}.reverse
end

def traceBackFrom x, n = 5
  result = []
  while x != n do
    result << x
    x = back x
  end
  result << x
  result.reverse
end

def chainDown x, n = 10
	print chain(x, n).map{|x| "#{x} -> #{down x}"}.join("\n")
	print "\n"
end