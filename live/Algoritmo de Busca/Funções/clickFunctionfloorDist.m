function clickFunctionfloorDist(src,~)
    Dist = evalin('base','Dist');
    pt = get(gca,'CurrentPoint');
    pt = floor(pt/Dist);
    assignin('base','clickPoint',pt)
end

