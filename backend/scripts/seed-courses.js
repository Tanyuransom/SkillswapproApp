const coursesData = [
  // --- Year One - Level 1 (Common to ICT, ISN, CS, SEN, CYS) ---
  { category: 'Engineering', name: 'Discrete Mathematics', code: 'MTH 1221', level: 1, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'CS', name: 'Object Oriented Programming with C++', code: 'CSC 1221', level: 1, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'ISN', name: 'Introduction to Networking', code: 'ISN 1231', level: 1, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'CS', name: 'Algorithms and Data Structures II', code: 'CSC 1222', level: 1, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'CS', name: 'Research Methodology for Computer Science Engineers', code: 'CSC 1121', level: 1, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'Engineering', name: 'Real Analysis II', code: 'MTH 1223', level: 1, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'BMS', name: 'Knowledge Leadership and African Development', code: 'BMS 1232', level: 1, specialty: 'ICT,ISN,CS,SEN,CYS' },

  // --- Year Two - Level 2 (Common to ICT, ISN, CS, SEN, CYS) ---
  { category: 'SEN', name: 'Object Oriented Analysis, Design and Implementation', code: 'SEN 2241', level: 2, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'ICT', name: 'Database Management Systems', code: 'ICT 2211', level: 2, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'SEN', name: 'Java Programming II', code: 'SEN 2242', level: 2, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'Engineering', name: 'Computational Mathematics', code: 'MTH 2222', level: 2, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'CS', name: 'Operating Systems', code: 'CSC 2221', level: 2, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'Engineering', name: 'Civics and Ethics', code: 'CVE 2200', level: 2, specialty: 'ICT,ISN,CS,SEN,CYS,JMC' },
  { category: 'ISN', name: 'Computer Networking and Security', code: 'ISN 2231', level: 2, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'SEN', name: 'Introduction to Game Development', code: 'SEN 2243', level: 2, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'CS', name: 'Introduction to IOT and Embedded Systems', code: 'CSC 2222', level: 2, specialty: 'ICT,ISN,CS,SEN,CYS' },

  // --- Year Three - Level 3 (BSc. ICT) ---
  { category: 'ICT', name: 'IT Infrastructure Management', code: 'ICT 3211', level: 3, specialty: 'ICT' },
  { category: 'SEN', name: 'Android Application Development', code: 'SEN 3242', level: 3, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'SEN', name: 'Advanced Web Development', code: 'SEN 3243', level: 3, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'SEN', name: 'Software Architecture', code: 'SEN 3244', level: 3, specialty: 'ICT,SEN,CS' },
  { category: 'ICT', name: 'Advanced Database Systems', code: 'ICT 3212', level: 3, specialty: 'ICT,SEN' },
  { category: 'CS', name: 'Introduction to Data Science', code: 'CSC 3221', level: 3, specialty: 'ICT,ISN,CS,SEN,CYS' },

  // --- Year Three - Level 3 (BSc. Software Engineering) ---
  { category: 'SEN', name: 'Software Validation and Verification', code: 'SEN 3241', level: 3, specialty: 'SEN,CS' },

  // --- Year Three - Level 3 (BSc. Computer Science) ---
  { category: 'CYS', name: 'Network/Computer Forensics', code: 'CYS 3251', level: 3, specialty: 'CS,ISN,CYS' },

  // --- Year Three - Level 3 (BSc. Information System & Networking) ---
  { category: 'ISN', name: 'Network Management', code: 'ISN 3231', level: 3, specialty: 'ISN,CYS' },
  { category: 'ISN', name: 'CCNA2', code: 'ISN 3232', level: 3, specialty: 'ISN,CYS' },

  // --- Year Four - Level 4 (BSc. ICT / SEN / CS / ISN / CYS) ---
  { category: 'ICT', name: 'Industrial Internship', code: 'ICT 4211', level: 4, specialty: 'ICT,ISN,CS,SEN,CYS' },
  { category: 'ICT', name: 'Individual Research Project', code: 'ICT 4212', level: 4, specialty: 'ICT,ISN,CS,SEN,CYS' },

  // --- Year Three - Level 3 (BSc. Renewable Energy) ---
  { category: 'BMS', name: 'Project Management', code: 'BMS 4238', level: 3, specialty: 'REN' },
  { category: 'REN', name: 'Hydrogen and Fuel Cells', code: 'REN 3261', level: 3, specialty: 'REN' },
  { category: 'REN', name: 'Application of Renewable Energy Software', code: 'REN 3262', level: 3, specialty: 'REN' },
  { category: 'REN', name: 'Sustainable Energy Management and Climate Change', code: 'REN 3263', level: 3, specialty: 'REN' },
  { category: 'REN', name: 'Power Plant Technology', code: 'REN 3264', level: 3, specialty: 'REN' },
  { category: 'REN', name: 'Embedded Systems', code: 'REN 3265', level: 3, specialty: 'REN' },

  // --- Year Four - Level 4 (BSc. Renewable Energy) ---
  { category: 'REN', name: 'Industrial Attachment', code: 'REN 4261', level: 4, specialty: 'REN' },
  { category: 'REN', name: 'Final Year Project', code: 'REN 4262', level: 4, specialty: 'REN' },

  // --- Year Two - Level 2 (BSc. Applied ICT in Journalism and Mass Communication) ---
  { category: 'JMC', name: 'Mobile Application Development for Journalists', code: 'JMC 2271', level: 2, specialty: 'JMC' },
  { category: 'JMC', name: 'Newspaper Editing and Printing', code: 'JMC 2272', level: 2, specialty: 'JMC' },
  { category: 'JMC', name: 'Radio and TV Programme Writing', code: 'JMC 2273', level: 2, specialty: 'JMC' },
  { category: 'JMC', name: 'Digital TV Production II', code: 'JMC 2274', level: 2, specialty: 'JMC' },
  { category: 'JMC', name: 'Digital Radio Production II', code: 'JMC 2275', level: 2, specialty: 'JMC' },
  { category: 'JMC', name: 'Music Production', code: 'JMC 2276', level: 2, specialty: 'JMC' },

  // --- Year Three - Level 3 (BSc. Applied ICT in Journalism and Mass Communication) ---
  { category: 'JMC', name: 'Digital Marketing', code: 'JMC 3271', level: 3, specialty: 'JMC' },
  { category: 'JMC', name: 'Cyber Journalism', code: 'JMC 3272', level: 3, specialty: 'JMC' },
  { category: 'JMC', name: 'Research Methods in Media', code: 'JMC 3273', level: 3, specialty: 'JMC' },
  { category: 'JMC', name: 'Entrepreneurship in Media', code: 'JMC 3274', level: 3, specialty: 'JMC' },
  { category: 'JMC', name: 'Film & Documentary Making', code: 'JMC 3275', level: 3, specialty: 'JMC' },
  { category: 'JMC', name: 'Sociology & Psychology in Media', code: 'JMC 3276', level: 3, specialty: 'JMC' },
];

async function call(port, path, method, data) {
  const url = `http://127.0.0.1:${port}${path}`;
  try {
    const response = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: data ? JSON.stringify(data) : undefined
    });
    if (!response.ok) throw new Error(`${url} -> HTTP ${response.status}: ${await response.text()}`);
    return response.json();
  } catch (e) {
    throw new Error(`Failed to call ${url}: ${e.message}`);
  }
}

async function updateSystem() {
  try {
    console.log('--- Cleaning Data ---');
    try { await call(3002, '/all-courses', 'DELETE'); console.log('Courses cleaned.'); } catch(e) { console.warn('Course cleanup warning:', e.message); }
    try { await call(3005, '/all-shorts', 'DELETE'); console.log('Shorts cleaned.'); } catch(e) { console.warn('Shorts cleanup warning:', e.message); }
    try { await call(3004, '/all', 'DELETE'); console.log('Categories cleaned.'); } catch(e) { console.warn('Category cleanup warning:', e.message); }

    console.log('--- Creating New Categories ---');
    const catMap = {};
    const categoryNames = ['Engineering', 'BMS', 'ICT', 'ISN', 'CS', 'SEN', 'CYS', 'REN', 'JMC'];
    
    for (const name of categoryNames) {
      const cat = await call(3004, '/', 'POST', { name, description: `${name} Studies` });
      catMap[name] = cat.id;
    }
    console.log('Categories created:', Object.keys(catMap));

    console.log('--- Seeding Courses ---');
    for (const course of coursesData) {
      await call(3002, '/', 'POST', {
        title: `${course.name} (${course.code})`,
        description: `Academic course for ${course.name} [${course.code}] in ${course.category} (Level ${course.level})${course.specialty ? ' - ' + course.specialty : ''}`,
        price: 0,
        instructorId: 'system-seed',
        categoryId: catMap[course.category],
        level: course.level,
        specialty: course.specialty,
        status: 'active'
      });
      console.log(`Seeded: ${course.name} (${course.code})`);
    }

    console.log('--- DONE ---');
  } catch (error) {
    console.error('Update failed:', error.message);
  }
}

updateSystem();
