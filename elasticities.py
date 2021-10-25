import pandas as pd
import math

#read data
#Fernando and Monica, you might need to update this file path
data = pd.read_stata('italy_final.dta')
data_2006 = data[data['year']==2006]
data_2014 = data[data['year']==2014]

#sort by residual income
data_2006 = data_2006.sort_values(by = 'resid_income_actual')
data_2014 = data_2014.sort_values(by = 'resid_income_actual')

#Compute average for each bucket in 2006
avg_inc_2006 = []
avg_cons_2006 = []
bucket_size = round(len(data_2006.index)/10)
for i in range(10):
    curr_bucket = data_2006.iloc[i*bucket_size:(i+1)*bucket_size,:]
    avg_inc_2006.append(curr_bucket['resid_income_actual'].sum()/bucket_size)
    avg_cons_2006.append(curr_bucket['resid_consump_actual'].sum()/bucket_size)
    #print(curr_bucket)

print(avg_inc_2006)
print(avg_cons_2006)
#Compute average for each bucket in 2014
avg_inc_2014 = []
avg_cons_2014 = []
bucket_size = round(len(data_2014.index)/10)
for i in range(10):
    curr_bucket = data_2014.iloc[i*bucket_size:(i+1)*bucket_size,:]
    avg_inc_2014.append(curr_bucket['resid_income_actual'].sum()/bucket_size)
    avg_cons_2014.append(curr_bucket['resid_consump_actual'].sum()/bucket_size)

#Compute deltas
delta_inc = []
delta_cons = []
for i in range(10):
    delta_inc.append(math.log(avg_inc_2014[i]/avg_inc_2006[i]))
    delta_cons.append(math.log(avg_cons_2014[i]/avg_cons_2006[i]))

print("delta_inc",delta_inc)
print("delta_cons",delta_cons)
#Compute elasticity
elasticity = []
for i in range(10):
    elasticity.append(delta_cons[i]/delta_inc[i])

print(elasticity)


'''
#Split data into crisis year and non crisis years
crisis_data = data[(data['year']==2006)|(data['year']==2014)]

#Flag each observation in crisis data based on which bin it should be counted in
crisis_data['flag'] = -1
print(crisis_data)
crisis_data.sort_values(by = 'resid_income_actual')
bucket_size = round(len(crisis_data.index)/10)
counter = 1
decile = 1
for i in range(len(crisis_data.index)):
    #for some reason it doesn't like this line even though it works. Prob should change to ref col name instead of index
    crisis_data.iloc[i,27] = decile
    counter = counter+1
    if counter > bucket_size:
        counter = 0
        decile = decile + 1
'''






'''
#Split data by year
data_2004 = data[data['year']==2004]
data_2006 = data[data['year']==2006]
data_2012 = data[data['year']==2012]
data_2014 = data[data['year']==2014]

#Create 10 buckets for each year for resid income and coonsumption
all_data = [data_2004,data_2006,data_2012,data_2014]
inc_buckets = [[],[],[],[]]
consump_buckets = [[],[],[],[]]
for i in range(4):
    rows = len(all_data[i].index)
    bucket_size = round(rows/10)
    for j in range(10):
        all_data[i].sort_values(by='resid_income_actual')
        curr_inc_avg = all_data[i].iloc[j*bucket_size:(j+1)*bucket_size,:]['resid_income_actual'].sum()
        all_data[i].sort_values(by='resid_consump_actual')
        curr_consump_avg = all_data[i].iloc[j*bucket_size:(j+1)*bucket_size,:]['resid_consump_actual'].sum()
        inc_buckets[i].append(curr_inc_avg)
        consump_buckets[i].append(curr_consump_avg)

#Get deltas for two crisis years
delta_inc_buckets = [[],[]]
delta_consump_buckets = [[],[]]
for i in range(2):
    for j in range(10):
        delta_inc_buckets[i].append(inc_buckets[i+1][j]-inc_buckets[i][j])
        delta_consump_buckets[i].append(consump_buckets[i+1][j]-consump_buckets[i][j])

#Average deltas
avg_delta_inc_buckets = []
avg_delta_consump_buckets = []
for i in range(10):
    avg_delta_inc_buckets.append((delta_inc_buckets[0][i]+delta_inc_buckets[1][i])/2)
    avg_delta_consump_buckets.append((delta_consump_buckets[0][i]+delta_consump_buckets[1][i])/2)

#Generate elasticities
elasticities = []
for i in range(10):
    elasticities.append(avg_delta_consump_buckets[i]/avg_delta_inc_buckets[i])

print(elasticities)
'''