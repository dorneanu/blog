+++
title = "Using JQuery DataTables with IPython"
date = "2014-08-28"
tags = ["ipython", "python", "jquery", "javascript"] 
author = "Victor Dorneanu"
category = "blog"
+++

I thought this might be interesting enough to share with you. Every time I'm working with DataFrames I somehow miss the search feature: I'd like to search for certain patterns inside the columns and rows. I used to use [JQuery DataTables](https://datatables.net) for [netgrafio](http://dornea.nu/projects/netgrafio). But I couldn't find any simple way to integrate it with IPython. Well it was easier than I thought.


## Extensions


```
# <!-- collapse=True -->
from IPython import display
from IPython.core.magic import register_cell_magic, Magics, magics_class, cell_magic
import jinja2

# Create jinja cell magic (http://nbviewer.ipython.org/urls/gist.github.com/bj0/5343292/raw/23a0845ee874827e3635edb0bf5701710a537bfc/jinja2.ipynb)
@magics_class
class JinjaMagics(Magics):
    '''Magics class containing the jinja2 magic and state'''
    
    def __init__(self, shell):
        super(JinjaMagics, self).__init__(shell)
        
        # create a jinja2 environment to use for rendering
        # this can be modified for desired effects (ie: using different variable syntax)
        self.env = jinja2.Environment(loader=jinja2.FileSystemLoader('.'))
        
        # possible output types
        self.display_functions = dict(html=display.HTML, 
                                      latex=display.Latex,
                                      json=display.JSON,
                                      pretty=display.Pretty,
                                      display=display.display)

    
    @cell_magic
    def jinja(self, line, cell):
        '''
        jinja2 cell magic function.  Contents of cell are rendered by jinja2, and 
        the line can be used to specify output type.

        ie: "%%jinja html" will return the rendered cell wrapped in an HTML object.
        '''
        f = self.display_functions.get(line.lower().strip(), display.display)
        
        tmp = self.env.from_string(cell)
        rend = tmp.render(dict((k,v) for (k,v) in self.shell.user_ns.items() 
                                        if not k.startswith('_') and k not in self.shell.user_ns_hidden))
        
        return f(rend)
        
    
ip = get_ipython()
ip.register_magics(JinjaMagics)
```

## DataTable function


```
# <!-- collapse=True -->
import uuid

def DataTable(df):
    """ Prints a pandas.DataFrame as JQuery DataTables """
    from IPython.display import HTML
    # Generate random container name
    id_container = uuid.uuid1()
    output = """
        <div id="datatable-container-%s">
            <link rel="stylesheet" type="text/css" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.0/css/jquery.dataTables.css">
            <link rel="stylesheet" type="text/css" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.0/css/jquery.dataTables_themeroller.css">
            <script type="text/javascript" charset="utf8" src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.0/jquery.dataTables.min.js"></script>

            <script type="text/javascript">
                var url = window.location.href;
                
                if(url.indexOf("localhost:9999") != -1){
                    $('#datatable-container-%s table.datatable').dataTable();
                } else {
                    $.getScript("http://code.jquery.com/jquery-1.11.1.min.js");
                    $(document).ready(function() {
                        $('#datatable-container-%s table.datatable').dataTable();
                    });
                }
                
            </script>
            <!-- Insert table below -->
            %s
        </div>
    """ % (id_container, id_container, id_container, df.to_html(index=False, classes="datatable dataframe"))
    return HTML(output)
```


```

```

I know the code is not perfect, but at least it works for me. Now let's create some random DataFrame: 


```
import pandas as pd
import urllib2
from yurl import URL


# Fetch list of random URLs (found using Google)
response = urllib2.urlopen('http://files.ianonavy.com/urls.txt')
targets_row = response.read()

# Create DataFrame
targets = pd.DataFrame([t for t in targets_row.splitlines()], columns=["Target"])

# Join root domain + suffix
extract_root_domain =  lambda x: '.'.join(tldextract.extract(x)[1:3])

target_columns = ['scheme', 'userinfo', 'host', 'port', 'path', 'query', 'fragment', 'decoded']
target_component = [list(URL(t)) for t in targets['Target']]

# Create data frame
df_targets = pd.DataFrame(target_component, columns=target_columns)
```

### Classic HTML output


```
df_targets[:20]
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>scheme</th>
      <th>userinfo</th>
      <th>host</th>
      <th>port</th>
      <th>path</th>
      <th>query</th>
      <th>fragment</th>
      <th>decoded</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0 </th>
      <td> http</td>
      <td> </td>
      <td>               www.altpress.org</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>1 </th>
      <td> http</td>
      <td> </td>
      <td>           www.nzfortress.co.nz</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>2 </th>
      <td> http</td>
      <td> </td>
      <td>         www.evillasforsale.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>3 </th>
      <td> http</td>
      <td> </td>
      <td>           www.playingenemy.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>4 </th>
      <td> http</td>
      <td> </td>
      <td>      www.richardsonscharts.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>5 </th>
      <td> http</td>
      <td> </td>
      <td>                 www.xenith.net</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>6 </th>
      <td> http</td>
      <td> </td>
      <td>             www.tdbrecords.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>7 </th>
      <td> http</td>
      <td> </td>
      <td>   www.electrichumanproject.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>8 </th>
      <td> http</td>
      <td> </td>
      <td>      tweekerchick.blogspot.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>9 </th>
      <td> http</td>
      <td> </td>
      <td>                www.besound.com</td>
      <td> </td>
      <td> /pushead/home.html</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>10</th>
      <td> http</td>
      <td> </td>
      <td> www.porkchopscreenprinting.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>11</th>
      <td> http</td>
      <td> </td>
      <td>           www.kinseyvisual.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>12</th>
      <td> http</td>
      <td> </td>
      <td>             www.rathergood.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>13</th>
      <td> http</td>
      <td> </td>
      <td>                 www.lepoint.fr</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>14</th>
      <td> http</td>
      <td> </td>
      <td>                  www.revhq.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>15</th>
      <td> http</td>
      <td> </td>
      <td>        www.poprocksandcoke.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>16</th>
      <td> http</td>
      <td> </td>
      <td>            www.samuraiblue.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>17</th>
      <td> http</td>
      <td> </td>
      <td>                www.openbsd.org</td>
      <td> </td>
      <td>   /cgi-bin/man.cgi</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>18</th>
      <td> http</td>
      <td> </td>
      <td>                www.sysblog.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <th>19</th>
      <td> http</td>
      <td> </td>
      <td>         www.voicesofsafety.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
  </tbody>
</table>
</div>



### JQuery DataTables output


```
DataTable(df_targets[:20])
```





        <div id="datatable-container-aab341ae-2f8d-11e4-95d5-52540086692e">
            <link rel="stylesheet" type="text/css" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.0/css/jquery.dataTables.css">
            <link rel="stylesheet" type="text/css" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.0/css/jquery.dataTables_themeroller.css">
            <script type="text/javascript" charset="utf8" src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.0/jquery.dataTables.min.js"></script>

            <script type="text/javascript">
                var url = window.location.href;

                if(url.indexOf("localhost:9999") != -1){
                    $('#datatable-container-aab341ae-2f8d-11e4-95d5-52540086692e table.datatable').dataTable();
                } else {
                    $.getScript("http://code.jquery.com/jquery-1.11.1.min.js");
                    $(document).ready(function() {
                        $('#datatable-container-aab341ae-2f8d-11e4-95d5-52540086692e table.datatable').dataTable();
                    });
                }

            </script>
            <!-- Insert table below -->
            <table border="1" class="dataframe datatable dataframe">
  <thead>
    <tr style="text-align: right;">
      <th>scheme</th>
      <th>userinfo</th>
      <th>host</th>
      <th>port</th>
      <th>path</th>
      <th>query</th>
      <th>fragment</th>
      <th>decoded</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td> http</td>
      <td> </td>
      <td>               www.altpress.org</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>           www.nzfortress.co.nz</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>         www.evillasforsale.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>           www.playingenemy.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>      www.richardsonscharts.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                 www.xenith.net</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>             www.tdbrecords.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>   www.electrichumanproject.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>      tweekerchick.blogspot.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                www.besound.com</td>
      <td> </td>
      <td> /pushead/home.html</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td> www.porkchopscreenprinting.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>           www.kinseyvisual.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>             www.rathergood.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                 www.lepoint.fr</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                  www.revhq.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>        www.poprocksandcoke.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>            www.samuraiblue.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                www.openbsd.org</td>
      <td> </td>
      <td>   /cgi-bin/man.cgi</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                www.sysblog.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>         www.voicesofsafety.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
  </tbody>
</table>
        </div>




### Jinja2 cellmagic


```
html_output = DataTable(df_targets[:20])
```


```
%%jinja html
<div id="table-container">
    {{ html_output }}
</div>
```




<div id="table-container">
    <IPython.core.display.HTML object at 0x7f042eaa02d0>
</div>




```
html_output
```





        <div id="datatable-container-3b6a2692-2f8c-11e4-95d5-52540086692e">
            <link rel="stylesheet" type="text/css" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.0/css/jquery.dataTables.css">
            <link rel="stylesheet" type="text/css" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.0/css/jquery.dataTables_themeroller.css">
            <script type="text/javascript" charset="utf8" src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.0/jquery.dataTables.min.js"></script>

            <script type="text/javascript">
                $('#datatable-container-3b6a2692-2f8c-11e4-95d5-52540086692e table.datatable').dataTable();
            </script>
            <!-- Insert table below -->
            <table border="1" class="dataframe datatable dataframe">
  <thead>
    <tr style="text-align: right;">
      <th>scheme</th>
      <th>userinfo</th>
      <th>host</th>
      <th>port</th>
      <th>path</th>
      <th>query</th>
      <th>fragment</th>
      <th>decoded</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td> http</td>
      <td> </td>
      <td>               www.altpress.org</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>           www.nzfortress.co.nz</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>         www.evillasforsale.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>           www.playingenemy.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>      www.richardsonscharts.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                 www.xenith.net</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>             www.tdbrecords.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>   www.electrichumanproject.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>      tweekerchick.blogspot.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                www.besound.com</td>
      <td> </td>
      <td> /pushead/home.html</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td> www.porkchopscreenprinting.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>           www.kinseyvisual.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>             www.rathergood.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                 www.lepoint.fr</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                  www.revhq.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>        www.poprocksandcoke.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>            www.samuraiblue.com</td>
      <td> </td>
      <td>                  /</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                www.openbsd.org</td>
      <td> </td>
      <td>   /cgi-bin/man.cgi</td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>                www.sysblog.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
    <tr>
      <td> http</td>
      <td> </td>
      <td>         www.voicesofsafety.com</td>
      <td> </td>
      <td>                   </td>
      <td> </td>
      <td> </td>
      <td> False</td>
    </tr>
  </tbody>
</table>
        </div>




Easy isn't it? Thx for sharing.
