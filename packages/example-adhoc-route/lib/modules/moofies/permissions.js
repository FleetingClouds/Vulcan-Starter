import Users from 'meteor/vulcan:users';

const membersActions = [
  'moofies.new',
  'moofies.edit.own',
  'moofies.remove.own',
];
Users.groups.members.can(membersActions);

const adminActions = [
  'moofies.edit.all',
  'moofies.remove.all'
];
Users.groups.admins.can(adminActions);
