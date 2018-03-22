#!/usr/bin/py
import MySQLdb as my

class MY(object):

    def connect_database(self,HOST,USER,PWD,DB):
        connect = my.connect(HOST,USER,PWD,DB)
        open_database = connect.cursor(cursorclass=my.cursors.DictCursor)
        return connect,open_database
       
    def execute_show_sql(self,O,SQL):
        execute = O.execute(SQL)
        show_data = O.fetchall()
        print show_data

    def other_database(self,O,SQL,):
        O.execute(SQL,)


    def lose_execute(self,C,O):
        C.commit()
        O.close()
        C.close()


if __name__ == '__main__':
 
    def display(): 
        print '''
                              MySQL_Client_Tools 
                 ++++++++++++++++++++++++++++++++++++++++++++++
                 +		     1.append		      +
                 +		     2.delete		      +
                 +		     3.change	              +
                 +		     4.select		      +	 
                 +		     5.exit		      + 
                 ++++++++++++++++++++++++++++++++++++++++++++++
              '''
 
    HOST = raw_input('please input host: ')
    USER = raw_input('please input user: ')
    PWD  = raw_input('please input passwd: ')
    DB   = raw_input('please input db: ')

    display()
     
    mySQL = MY()
    try:
        C,O = mySQL.connect_database(HOST,USER,PWD,DB)
    except:
        print '\033[31musername or password error\033[0m'
        exit()

    option = raw_input('please input you of option: ')
    while True:
        if option == '4': 
            SQL = raw_input('please input SQL: ')
            try:
                mySQL.execute_show_sql(O,SQL)
            except:
                continue

        elif option == '1' or option == '2' or option == '3':
            SQL = raw_input('please input SQL: ')
            try:
                mySQL.other_database(O,SQL,)
            except:
                continue

        elif option == '5':
            exit()

        else:
            print '\033[31moption error\033[0m' 
	    continue 
    mySQL.lose_execute(C,O)




