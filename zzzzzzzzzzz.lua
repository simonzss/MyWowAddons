function f(...)
    a = select(3,...)  -->从第三个位置开始，变量 a 对应右边变量列表的第一个参数
    print (a)
    print (select(2,...)) -->打印所有列表参数
end

f(0,1,2,3,4,5)