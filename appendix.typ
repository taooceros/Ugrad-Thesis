#import "template.typ": *

#show: thesis-body

#let data = (
  4718000,
  83547000,
  110377000,
  900000,
  246000,
  77982000,
  88000,
  1428000,
  184968000,
  50499000,
  305202000,
  109764000,
  333000,
  139593000,
  2734000,
  103293000,
)

#figure(caption: [Execution statistics for Naive #fc-channel])[
    #table(columns: 4, table.cell(colspan: 4, [Execution statistics for Naive #fc-channel]), ..data.map(str))
]<table:fc-channel-naive-1-stats>