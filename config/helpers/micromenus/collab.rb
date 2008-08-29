heading "Adhearsion Micromenus Home"

# Below is a simple example of a helper used in a Micromenu.
# item oscar_wilde_quote + ' - Oscar Wilde'

# Use dial plan logic here in the Micromenu!
call "Check your voicemail!" do
  check_voicemail
end

# If you have Adhearsion's Asterisk Manager Interface configured
# properly, you can use the guess_sip_user feature.
item "My User!" do
  guess = guess_sip_user
  item guess ? guess : "Sorry, you're behind a NAT or on a PC."
end

item "Employee Collaboration" do
  item "View SIP users" do
    sip_users = PBX.sip_users
    items sip_users.collect(&:ip)
  end
  
  item "Add someone to the conference" do
    # Originate a call into the user
  end
  item "Have Tweedledum call Tweedledee" do
    x = PBX.rami_client.originate 'Context' => 'internal', 'Exten' => '11', 'Priority' => '1', 'Channel' => 'SIP/tweedledum'
    item x.inspect
  end
end

item 'Adhearsion Server Statistics' do
  item 'View Registered SIP Users' do
    PBX.sip_users.each do |u|
      item %(SIP user "#{u.username}" on IP #{u.ip})
    end
  end
  item 'View System Uptime' do
     item `uptime`
  end
  item 'Network' do
    heading 'Network Interface Info'
    `ifconfig eth1`.each_line do |line|
      item line
    end
  end
end

item 'View Users' do
  item 'Select a user to call below.'
  begin
    User.find(:all).each { |user| call user.extension, user.name }
  rescue
    item "Tried to use an ActiveRecord User class, but one didn't exist!"
    item "Have you configured your database?"
  end
end

image 'tux'