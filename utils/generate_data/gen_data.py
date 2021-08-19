# Simple script to generate some random fact table data in a CSV
import pandas as pd
from random import randrange
import datetime 

df_cities = pd.read_csv('worldcities.csv')

print(df_cities["id"])

lines = 100000

div= ["ACD", "CPD", "LUXE", "PPD"]

def random_date(start):
   return start + datetime.timedelta(days=randrange(360), hours=randrange(24), minutes=randrange(60))


f = open(f"fake_fact_table.csv", "w")
f.write("id,sell,division,date,city_id\n")

startDate = datetime.datetime(2013, 9, 20,13,00)

for i in range(lines):
    f.write(str(i) + ",") #id

    f.write(str(randrange(100000)) + ",") #sell in €

    random_div = div[randrange(len(div))]
    f.write(random_div + ",") #division
    f.write(str(random_date(startDate)) + ",") #date
    f.write(str(df_cities["id"].sample().values[0])) #city_id
    f.write("\n")

f.close()
