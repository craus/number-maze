def reload
	load './lib.rb'
end

def nextPos x
	x % 3 == 1 ? x + 4 : x + 2
end

@goalStop = 0.1

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
3.times { @goals << rndGoal }
@score = 0

def set x
	@pos = x
end

def forward x 
	x % 2 == 0 ? forward(x/2) : x
end

def left x 
	forward 3*x-1
end

def right x
	forward 3*x+1
end

def up x, n = 1
	n.times { x = [left(x), right(x)].max }
	x
end

def down x, n = 1
	n.times { x = [left(x), right(x)].min }
	x
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
		d = down x
		u = up x
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

def locs from = 5
	return Enumerator.new do |y|
		x = from
		loop {
			y << x
			x = nextPos(x)
		}
	end
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