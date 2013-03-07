# My Resume

This is where I store the data files and build tools for building my resume.  I do this because I wanted to have a single source of record for my career information in a simple data format, but I wanted to be able to use it to build different resumes (public html, public pdf, private pdf with contact info, grad school applications that have more school stuff and less career stuff, etc).

I use `templator` and Rake to build the resume.  Templator is another project of mine, also on GitHub [here](https://github.com/rodhilton/templator).

I'm making this project available on GitHub so others can use it as an example if they have a similar use case for creating their resumes as me.  Okay, not really, I'm storing it on GitHub because it's free and I'm a cheapskate.  But if someone is weird like me and wants to compile their resume, maybe it will be of use to someone else.

__Note:__ To deal with not wanting certain information like my phone number or e-mail address in a public site, the Rakefile reads from two `.gitignore`'d files, `contact.yaml` and `public.yaml`.  

##Templator Submodule

This repo uses templator so closely that it's actually a submodule.  After cloning, the Rake file won't build unless you do `git submodule init` and `git submodule update`.  Alternatively, it can be cloned with `git clone --recurse-submodules`