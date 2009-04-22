######################################################################
#=SimpleMail
#Copyright (C) 1999 R.Chambers
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
#02111-1307  USA
#
#==Name
#
# simplemail.rb - Provides a simple interface to popen'd sendmail.
#
# $Id: simplemail.rb,v 1.9 2003/07/27 10:06:16 nigelb Exp $
#
#==Synopsis
#
#      mail = SimpleMail.new
#      mail.to = "Colin <colin@rubycookbook.org>"
#      mail.from = "colin@rubycookbook.org"
#      mail.sender = "bounce@rubycookbook.org"
#      mail.subject = "This is a test"
#      mail.text = "This is some text in the text."
#      mail.html = "<b>big html stuff</b>"
#      mail.headers["X-Foobar"] = "Baz"
#      mail.attachementst << "/path/to/attachement/file.ext"
#      mail.send
#
#==Description
#
#SimpleMail is a simple wrapper class which popen's sendmail(1) to
#send email. It supports attachements and mutlipart/mixed messages
#with text and html content. This makes it ideal for mailing list type applications
#
#For binary attachments you will need uuencode, part of the sharutil package
#
#==History
#
# Date            Name                    Description
# 10/21/1999      R.Chambers              created
# 03/05/2001      Colin Steele            updated and ported to Ruby
# 03/02/2002      Nigel Ball              added installer
#                                         fixed mixed + attachments
#                                         converted to rdoc
# $Log: simplemail.rb,v $
# Revision 1.9  2003/07/27 10:06:16  nigelb
# Added example (may not be complete).
# Small update to documentation.
#
# Revision 1.8  2003/06/07 12:28:24  nigelb
# Updated documentation and removed broken test. Upgraded install
# to use installpgk. Cleaned up readme file. Made internal methods
# private.
#
# Revision 1.7  2003/05/28 17:02:47  nigelb
# Added support for text + attachments and fixed bug in attachment code
# which left the uuencode header line in the file. This upsets some
# applications.
#
#

require 'md5'

class SimpleMail

  DEFAULT_SENDMAIL_COMMAND = "/usr/sbin/sendmail -t"

  # No support for multiple addresses yet
  attr :to, true
  attr :bcc, true
  attr :cc, true
  
  # mail.from = "My Name <myname@my.domain.com>"
  # If the mail address is supplied in this format, sendmail is invoked with -F "My Name"
  # mail.from= "myname@my.domain.com"
  # Sets the From header.
  attr :from, true
  
  # mail.sender = "My Name <myname@my.domain.com>"
  # mail.sender = "myname@my.domain.com"
  # Sets the Return-to header and the From header if mail.from not set.
  attr :sender, true
  
  # mail.subject = "Mail message subject". Self explanitory. Optional.
  attr :subject, true
  
  # mail.headers["header"] = "header" sets the required header to the value supplied. Use for such purposes
  # as mail.headers["Mail-list"} = "My mailing list". Optional.
  attr :headers, true
  
  # mail.text = "text" sets the text/plain part of the e-mail message.  One of html or text must be set.
  attr :text, true
  
  # mail.html = "html text" sets the text/html part of the e-mail message. Do not set to send a simple text only email
  attr :html, true
  
  # mail.attachments << "/path/to/file.ext" adds attachments to the mail. Optional
  attr :attachments, true

  #sendmail_command is a string with a relative or absolute path to
  #sendmail (or something equivalent).  DEFAULT_SENDMAIL_COMMAND is
  #"/usr/sbin/sendmail -t". Should also work with courier & qmail substitutes.

  def initialize(sendmail_command = DEFAULT_SENDMAIL_COMMAND)
    @cmd      = sendmail_command
    @to       = ""
    @subject  = "(No subject given.)"
    @cc       = ""
    @bcc      = ""
    @headers  = {}
    @html     = ""
    @text     = ""
    @from     = ""
    @sender   = ""
    @attachments = []
  end

private
  #Low-level interface; thin wrapper around popen'd sendmail.
  #
  #Args to, subject, headers and body are Strings.  They contain the
  #recipient, subject of the email, other headers (like "From:") and the
  #body of the email, respectively.
  #
  #Returns the exit status of the popen'd command.
  #

  def sendToMailCmd(to, subject, headers, body)
    cmd = @cmd
    if @sender.empty?
      from, name = parseFrom(@from)
    else
      from, name = parseFrom(@sender)
      @headers['From'] = @from unless @from.empty?
    end
    if from
      cmd += " -f #{from}"
      cmd += " -F '#{name}'" if name
      sendmail = IO.popen(cmd, "w+")
      sendmail.puts("To: " + to)
      sendmail.puts("Subject: " + subject)
      sendmail.puts(headers) if (headers && headers != "")
      sendmail.puts("\n" + body) if (body && body != "")
      sendmail.close
      return $? && $? >> 8
    end
    -1
  end

  #
  #Returns String containing headers appropriate for the text portion of
  #a multipart MIME message.
  #
  
  def formatTextHeader
    outTextHeader = "Content-Type: text/plain; charset=us-ascii\n"
    outTextHeader += "Content-Transfer-Encoding: 7bit\n\n"
    outTextHeader += @text + "\n"
  end

  #
  #Returns String containing headers appropriate for the HTML portion of
  #a multipart MIME message.
  #

  def formatHTMLHeader
    outHTMLHeader = "Content-Type: text/html; charset=us-ascii\n"
    outHTMLHeader += "Content-Transfer-Encoding: 7bit\n\n"
    if @html && @html != ""
      outHTMLHeader += @html + "\n"
    end
    outHTMLHeader
  end

  #
  #Returns String containing all headers formatted for sending to
  #sendmail.
  #

  def allHeaders
    mailHeader = ""
    # --add CC
    mailHeader += "CC: " + @cc + "\n" if (@cc != "")
    # --add BCC
    mailHeader += "BCC: " + @bcc + "\n" if (@bcc != "")
    # --add From
    mailHeader += "From: " + @from + "\n" if (@from != "")
    # --add extras
    @headers.each { |key, val|
      mailHeader += key + ": " + val + "\n"
    }
    mailHeader
  end

#
#Returns a suitably random String for use in separating MIME parts.
#

  def getRandomBoundary(offset = 0)
    "----" + MD5.new(Time::now.to_s + rand.to_s + offset.to_s).hexdigest
  end

public
  #
  #High-level interface to send mail.  Transmits the mail using the
  #previously supplied body, to, from, etc.
  #
  #We send one of:
  #* text only
  #* text and html
  #* text, html and attachments
  #* text and attachments

  def send
    if ((@text != "") &&
        (@html == "") &&
        (@attachments.size == 0))
      # --TEXT ONLY

      return sendToMailCmd(@to,
                           @subject,
                           allHeaders,
                           @text)
                           
    elsif((@text != "") &&
          (@html != "") &&
          (@attachments.size == 0))

      # --HTML AND TEXT
      
      # --get random boundary for content types
      textBoundary = getRandomBoundary
      # --format headers for text and html portions
      textHeader = formatTextHeader
      htmlHeader = formatHTMLHeader
      
      # --start with caller-supplied headers
      mailHeader = allHeaders
      # --set MIME-Version
      mailHeader += "MIME-Version: 1.0\n"
      # --set up main content header with boundary
      mailHeader += "Content-Type: multipart/alternative;\n"
      mailHeader += ' boundary="' + textBoundary + '"'
      mailHeader += "\n\n\n"
      # --add text and boundaries
      mailHeader += "--" + textBoundary + "\n"
      mailHeader += textHeader + "\n"
      mailHeader += "--" + textBoundary + "\n"
      # --add html and ending boundary
      mailHeader += htmlHeader
      mailHeader += "\n--" + textBoundary + "--"
      # --send message
      return sendToMailCmd(@to,
                           @subject,
                           mailHeader,
                           "")
    elsif((@text != "") &&
          (@html != "") &&
          (@attachments.size > 0))
      
      # --HTML AND TEXT AND ATTACHMENTS
      
      # --get random boundary for attachments
      attachmentBoundary = getRandomBoundary
      
      # --start with caller-supplied headers
      mailHeader = allHeaders
      # --set MIME-Version
      mailHeader += "MIME-Version: 1.0\n"
      # --set main header for all parts and boundary
      mailHeader += "Content-Type: multipart/mixed;\n"
      mailHeader += ' boundary="' + attachmentBoundary + '"' + "\n\n"
      #mailHeader += "This is a multi-part message in MIME format.\n"
      mailHeader += "--" + attachmentBoundary + "\n"
      
      # --TEXT AND HTML--
      # --get random boundary for content types
      textBoundary = getRandomBoundary(1)
      # --format headers
      textHeader = formatTextHeader
      htmlHeader = formatHTMLHeader
      # --set up main content header with boundary
      mailHeader += "Content-Type: multipart/alternative;\n"
      mailHeader += ' boundary="' + textBoundary + '"'
      mailHeader += "\n\n\n"
      # --add text and boundaries
      mailHeader += "--" + textBoundary + "\n"
      mailHeader += textHeader
      mailHeader += "--" + textBoundary + "\n"
      # --add html and ending boundary
      mailHeader += htmlHeader
      mailHeader += "\n--" + textBoundary + "--"
      # --END TEXT AND HTML
      # --get array of attachment filenames
      if @attachments && @attachments.size != 0
        # --loop through each attachment
        @attachments.each { |item|
          # --attachment separator
          mailHeader += "\n--" + attachmentBoundary + "\n"
          # --get attachment info
          mailHeader += formatAttachmentHeader(item)
        }
        mailHeader += "--" + attachmentBoundary + "--"
      end

      return sendToMailCmd(@to,
                           @subject,
                           mailHeader,
                           "")
    elsif((@text != "") &&
          (@html == "") &&
          (@attachments.size > 0))
      
      # --TEXT AND ATTACHMENTS
      
      # --get random boundary for attachments
      attachmentBoundary = getRandomBoundary
      
      # --start with caller-supplied headers
      mailHeader = allHeaders
      # --set MIME-Version
      mailHeader += "MIME-Version: 1.0\n"
      # --set main header for all parts and boundary
      mailHeader += "Content-Type: multipart/mixed;\n"
      mailHeader += ' boundary="' + attachmentBoundary + '"' + "\n\n"
      #mailHeader += "This is a multi-part message in MIME format.\n"
      mailHeader += "--" + attachmentBoundary + "\n"
      
      # --TEXT
      # --format headers
      textHeader = formatTextHeader
      # --add text
      mailHeader += textHeader
      # --END TEXT
      # --get array of attachment filenames
      if @attachments && @attachments.size != 0
        # --loop through each attachment
        @attachments.each { |item|
          # --attachment separator
          mailHeader += "\n--" + attachmentBoundary + "\n"
          # --get attachment info
          mailHeader += formatAttachmentHeader(item)
        }
        mailHeader += "--" + attachmentBoundary + "--"
      end

      return sendToMailCmd(@to,
                           @subject,
                           mailHeader,
                           "")
    end
    return -1
  end # send

private
  #
  #Returns a String containing the MIME type for the supplied filename.
  #

  def getContentType (inFileName)
    
    # --strip path
    inFileName = File.basename(inFileName)
    
    # --check for no extension
    extension = inFileName.sub(/[^.]+(\..*)/, '\1')
    if extension == ""
      return "application/octet-stream"
    end
    
    # --get extension and check cases
    case extension
    when ".gif"
      return "image/gif"
    when ".gz"
      return "application/x-gzip"
    when ".htm"
      return "text/html"
    when ".html"
      return "text/html"
    when ".jpg"
      return "image/jpeg"
    when ".tar"
      return "application/x-tar"
    when ".txt"
      return "text/plain"
    when ".zip"
      return "application/zip"
    when ".pdf"
      return "application/pdf"
    end
    "application/octet-stream"
  end # getContentType

  #
  #Returns a String containing the attachments formatted for transmittal
  #to sendmail.
  #

  def formatAttachmentHeader (inFileLocation)
    
    outAttachmentHeader = ""
    
    # --get content type based on file extension
    contentType = getContentType(inFileLocation)
    
    # --if content type is TEXT the standard 7bit encoding
    if contentType =~ /text/
      # --format header
      outAttachmentHeader  += "Content-Type: " + contentType + ";\n"
      outAttachmentHeader  += ' name="' + File.basename(inFileLocation) +
                              '"' + "\n"
      outAttachmentHeader  += "Content-Transfer-Encoding: 7bit\n"
      outAttachmentHeader  += "Content-Disposition: attachment;\n";
      outAttachmentHeader  += ' filename="' + File.basename(inFileLocation) +
                              '"' + "\n\n"
      textFile = File.new(inFileLocation)
      # --loop through file, line by line
      outAttachmentHeader += textFile.readlines.join("\n")
      textFile.close
      outAttachmentHeader  += "\n"
      
      # --NON-TEXT use 64-bit encoding
    else
      # --format header
      outAttachmentHeader  += "Content-Type: " + contentType + ";\n"
      outAttachmentHeader  += ' name="' + File.basename(inFileLocation) +
                              '"' + "\n"
      outAttachmentHeader  += "Content-Transfer-Encoding: base64\n"
      outAttachmentHeader  += "Content-Disposition: attachment;\n";
      outAttachmentHeader  += ' filename="' + File.basename(inFileLocation) +
                              '"' + "\n\n"
      # --call uuencode - output is returned to the return array
      res = `uuencode -m #{inFileLocation} #{File.basename(inFileLocation)}`
      # --add each line returned
      # discard the first line
      resLines = res.split("\n")
      resLines.delete_at(0)
      res = resLines.join("\n")
      outAttachmentHeader  += res
    end
    
    outAttachmentHeader

  end # formatAttachmentHeader

  #Parses an address into the name and address components
  def parseFrom(fromIn)
    from = name = nil
    return from, name if fromIn.nil? || fromIn.empty?
    ary = fromIn.split
    from = ary.pop
    if from && from[0] == ?<
      from = from[1..-2]
    end
    name = ary.join(' ') if ary.size > 0
    name = name[1..-2] if name && name[0] == ?"
    return from, name
  end
  
end # class

