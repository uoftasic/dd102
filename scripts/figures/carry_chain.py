"""The carry chain: cin enters fa0, each adder's carry feeds the next, cout leaves fa3."""
import schemdraw.flow as flow

from circuit_style import drawing, save

d = drawing()
arrow = d.add(flow.Arrow().right(d.unit * 0.55).label("cin", loc="left", ofst=0.15))
for i in range(4):
    box = d.add(flow.Box(w=1.4, h=1.0).anchor("W").at(arrow.end).label(f"fa{i}"))
    if i < 3:
        arrow = d.add(flow.Arrow().right(d.unit * 0.75).at(box.E).label(f"c[{i + 1}]", loc="top", ofst=0.1))
d.add(flow.Arrow().right(d.unit * 0.55).at(box.E).label("cout", loc="right", ofst=0.15))
print(save(d, "dd102-carry-chain"))
