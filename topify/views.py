from a_Model import ModelIt
from flask import request
from flask import render_template
from topify import app
from sqlalchemy import create_engine
from sqlalchemy_utils import database_exists, create_database
import pandas as pd
import psycopg2

user = 'ceboylan' #add your username here (same as previous postgreSQL)                      
host = 'localhost'
dbname = 'topify_db'
db = create_engine('postgres://%s%s/%s'%(user,host,dbname))
con = None
con = psycopg2.connect(database = dbname, user = user)

if not database_exists(db.url):
    create_database(db.url)
master = pd.DataFrame.from_csv('master_topic_info_sums_imgs.csv')
master.to_sql('master_data_table', db, if_exists='replace')

@app.route('/')
@app.route('/index')
def index():
   return "Hello, World!"
   
@app.route('/input')
def cesareans_input():
    return render_template("input.html")

@app.route('/output')
def cesareans_output():
  #pull 'genre' from input field and store it
  patient = request.args.get('genre')
  tags = request.args.get('input_tags')
  summary = request.args.get('input_summary')
  fromUser = tags+' '+summary
  # genre_label = str(patient)
    #just select the topic info from the topify database for the genre that the user inputs
  query = "SELECT topic_proportion, topic_num, rep_url, rep_summary, term_str, img FROM master_data_table WHERE genre='%s'" % patient
  print query
  query_results=pd.read_sql_query(query,con)
  print query_results
  topics = []
  keyinput = ''
  for i in range(0,query_results.shape[0]):
      topics.append(dict(topic_proportion=str(query_results.iloc[i]['topic_proportion']), rep_summary=query_results.iloc[i]['rep_summary'], rep_url=query_results.iloc[i]['rep_url'], topic_num=query_results.iloc[i]['topic_num'], term_str=query_results.iloc[i]['term_str'], img=query_results.iloc[i]['img']))
      keyinput += str(query_results.iloc[i]['term_str'])
      keyinput += ', '
      keywords = keyinput.split(", ")
  keywords.remove('')
  keywords.remove('None')    
  matching_keywords = []
  missing_keywords = []
  for keyword in keywords:
    if keyword in fromUser:
      matching_keywords.append(keyword)
    else:
      missing_keywords.append(keyword)
  matching_keywords = list(set(matching_keywords))
  # the set() gets rid of duplicates, but also re-orders things in a seemingly random way
  # sorted(matching_keywords)
  # sorted(missing_keywords)
  missing_keywords = list(set(missing_keywords))
  return render_template("output.html", patient = patient, topics = topics, matching_keywords = matching_keywords, missing_keywords = missing_keywords)