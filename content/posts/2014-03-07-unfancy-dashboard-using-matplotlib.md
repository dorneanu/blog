+++
title = "Unfancy dashboard using matplotlib"
author = "Victor"
date = "2014-03-07"
tags = ["coding", "misc", "web", "viz", "python", "matplotlib"]
category = "blog"
+++

I was recently playing around with [D3][1]Â and discovered its dashboard posibilities.[ dashboarddude.com][2]Â has a nice compilation of really fancy dashboards (I was mainly interested in D3 but voila... there are also other ways to do it).

Meanwhile I was remembered of old good [IPython Notebook][3] and its plotting features. This is what came out (You can find the code also on **Github Gist**: <https://gist.github.com/dorneanu/9407737>):

~~~ python
import datetime as dt
import matplotlib.dates as mdates
from mpl_toolkits.axes_grid.axislines import Subplot
from time import sleep

%matplotlib inline

def gen_dashboard():
    # Generate months
    months = []
    for i in range(1,13):
        months.append((i, datetime.date(2013, i, 1).strftime('%Y-%m')))

    # Generate data
    t_fixed = np.random.randint(50, size=len(months))
    t_closed = np.random.randint(100, size=len(months))
    t_open = np.random.randint(100, size=len(months))
    t_wip = np.random.randint(50, size=len(months))
    t_wfix = np.random.randint(50, size=len(months))

    # Set x axis
    x = np.array([i[1] for i in months])
    x = np.array([datetime.datetime(2013, 9, 28, i, 0) for i in range(12)])
    x = [dt.datetime.strptime(i[1],'%Y-%m').date() for i in months]

    # Create matplotlib figures
    my_dpi = 80

    ### Fig 1 ##########################################################
    fig1 = plt.figure(0,figsize=(2000/my_dpi, 900/my_dpi), dpi=my_dpi)
    fig1.add_subplot(221)
    plt.plot(x, t_fixed, marker='*', linestyle='-', color='g', label='Fixed')
    plt.plot(x, t_closed, marker='*', linestyle='--', color='b', label='Closed')
    plt.fill_between(x,t_closed,0,color='green')
    plt.fill_between(x,t_fixed,0,color='black')

    # Some dates settings
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
    plt.gca().xaxis.set_major_locator(mdates.MonthLocator())

    # Label axis
    plt.xlabel('Datum')
    plt.ylabel('# Issues')
    plt.legend(loc="upper right")
    plt.grid(True)

    ### Fig 2 ##########################################################
    fig2 = figure(0, figsize=(2000/my_dpi, 2000/my_dpi), dpi=my_dpi)
    fig2.add_subplot(222)
    plt.plot(x, t_wip, linestyle='--', color='b', label='Work in progress')
    plt.plot(x, t_closed, linestyle='--', color='r', label='Open')
    plt.legend()


    ### Fig 3 ##########################################################
    fig3 = figure(1, figsize=(2000/my_dpi, 1800/my_dpi), dpi=my_dpi)
    fig3.add_subplot(223)
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
    plt.gca().xaxis.set_major_locator(mdates.MonthLocator())

    plt.plot(x, t_wip, linestyle='--', color='b', label='Work in progress')
    plt.plot(x, t_open, linestyle='--', color='r', label='Open')
    plt.fill_between(x,t_wip,0,color='orange')
    #plt.fill_between(x,t_open,0,color='black')
    plt.legend()


    ### Fig 4 #########################################################
    fig4 = figure(1, figsize=(4,4))
    ax = fig4.add_subplot(224)
    #ax = Subplot(fig4, 224
    #ax = plt.axes([0.5, 0.5, 0.4, 0.4])
    # plt.axes([0.5, 0.5, 0.8, 0.8])
    labels = 'Closed', 'Fixed', 'Work in Progress', 'Won\'t Fix', 'Open'
    colors = ('orange', 'green', 'yellow', 'black', 'grey')
    fracs = np.random.randint(50, size=len(labels))
    plt.pie(fracs,labels=labels, colors=colors, autopct='%1.1f%%', shadow=True, startangle=90)
    plt.title('Issues overview')

    plt.show()


gen_dashboard()
~~~

The code just generates 4 time series data and displays them in several plots. A pie chart is also included. I hope somebody will find it useful.

And the result:

 [1]: http://d3js.org/
 [2]: http://dashboarddude.com/
 [3]: http://ipython.org/notebook
