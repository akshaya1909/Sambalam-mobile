// import bcrypt from 'bcryptjs';

// const users = [
//     {
//         phoneNumber: 9094860602,
//         password: bcrypt.hashSync('1234', 10),
//     },
    
//     {
//         phoneNumber: 6374364390,
//         password: bcrypt.hashSync('1234', 10),
//     },

//     {
//         phoneNumber: 9999999999,
//         password: bcrypt.hashSync('1234', 10),
//     }
// ];

// export default users;



import bcrypt from 'bcryptjs';

const users = [
  {
    phoneNumber: 9094860602,
    secure_pin: bcrypt.hashSync('1234'.toString(), 10),
    isVerified: true,
    companies: [], // To be filled after company creation
  },
  {
    phoneNumber: 6374364390,
    secure_pin: bcrypt.hashSync('1234'.toString(), 10),
    isVerified: true,
    companies: [],
  },
  {
    phoneNumber: 9999999999,
    secure_pin: bcrypt.hashSync('1234'.toString(), 10),
    isVerified: false,
    companies: [],
  },
];

export default users;
