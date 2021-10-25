import pandas as pd

#import data
#Fernando and Monica, you'll need to change the paths to match your directory
comp = pd.read_stata('storico_stata\\comp.dta')
rfam = pd.read_stata('storico_stata\\rfam.dta')
cons = pd.read_stata('storico_stata\\cons.dta')

#drop all rows with data before 1995 for efficiency as well as data on non hhold heads in comp
comp.drop(comp.loc[comp['anno']<1995].index, inplace=True)
comp.drop(comp.loc[comp['nord']!=1].index, inplace=True)
rfam.drop(rfam.loc[rfam['anno']<1995].index, inplace=True)
cons.drop(cons.loc[cons['anno']<1995].index, inplace=True)

#keep only relevant rows for efficiency
#eta:age oh hhold head, acom5:num local residents, ncomp:hhold size, sesso:sex, studio:educ(categorical),ireg:categorical region
comp = comp[['nquest','anno','eta','acom5','ncomp','sesso','studio','ireg']]
cons = cons[['nquest','anno','c','cn']]
rfam = rfam[['nquest','anno','yl1','yt','ym','yc','yl2','yca','ycf']]

#reset indices for joining datasets
comp.set_index(['nquest','anno'],drop=True,inplace=True)
cons.set_index(['nquest','anno'],drop=True,inplace=True)
rfam.set_index(['nquest','anno'],drop=True,inplace=True)

#join data
data = comp.join(rfam,on=['nquest','anno'],rsuffix='_extra')
data = data.join(cons,on=['nquest','anno'],rsuffix='_extra')
print("All data from 1995-2016: ",len(data.index)," vs: 86,729")

#Create stata file with all data from 1995-2016
data.to_stata('italy_uncleaned.dta')

#drop residents in small locations
data.drop(data.loc[data['acom5']==1].index, inplace=True)
print("After dropping residents in small locations: ",len(data.index), " vs: 75,977")

#drop obs where household head age <25 or > 60
#For some reason this leaves us with 42,202 observations instead of 43,505 as in paper
data.drop(data.loc[data['eta']<=25].index, inplace=True)
data.drop(data.loc[data['eta']>=60].index, inplace=True)
print("After dropping ages outside 25-60: ",len(data.index), " vs: 43,505")

#Create consumption and income columns
data['income'] = data['yl1']+data['yt']+data['ym']+data['yc']
data['consump'] = data['cn']
data['inc_cons_ratio'] = data['income']/data['consump']

#Remove obeservations with negative income
data.drop(data.loc[data['income']<0].index, inplace=True)

#Remove top and bottom .05% of data so .005*42,202 = 211.01
#After have 41745 obs vs 42286 in paper
sorted_data = data.sort_values(by='inc_cons_ratio')
trimmed_data = sorted_data.iloc[211:-211]
print("After dropping outliers and negative income: ",len(trimmed_data.index)," vs: 42,286")

#Only keep data in crisis periods of 2006 and 2014. Final data has 7033 obs vs 7060, so about 99.9% the same
trimmed_data.reset_index(inplace=True)
trimmed_data = trimmed_data[(trimmed_data['anno']==2006)|(trimmed_data['anno']==2014)]
print("After dropping non crisis years: ",len(trimmed_data.index), " vs: 7,060")

#Create education col as in paper. 
trimmed_data['educ'] = 1
for i in range(0,len(trimmed_data.index)):
    if trimmed_data.iloc[i,6] < 3:
        trimmed_data.iloc[i,-1] = 1
    if trimmed_data.iloc[i,6] == 3.0:
        trimmed_data.iloc[i,-1] = 2
    if trimmed_data.iloc[i,6] > 3:
        if trimmed_data.iloc[i,6] < 6:
            trimmed_data.iloc[i,-1] = 3
    if trimmed_data.iloc[i,6] > 5:
        trimmed_data.iloc[i,-1] = 4

#Deflate income and consumption using OECD CPI data
print(trimmed_data)
for i in range(0,len(trimmed_data.index)):
    if trimmed_data.iloc[i,1]==2006:
        trimmed_data.iloc[i,-3] = trimmed_data.iloc[i,-3]/(86.4/100)
        trimmed_data.iloc[i,-4] = trimmed_data.iloc[i,-4]/(86.4/100)
    if trimmed_data.iloc[i,1]==2014:
        trimmed_data.iloc[i,-3] = trimmed_data.iloc[i,-3]/(99.9/100)
        trimmed_data.iloc[i,-4] = trimmed_data.iloc[i,-4]/(99.9/100)

#export cleaned data to stata
trimmed_data.to_stata('italy_cleaned.dta')
#print(trimmed_data)
