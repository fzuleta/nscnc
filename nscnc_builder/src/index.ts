import * as fs from 'fs';
import * as path from 'path';

interface FileDescriptor {
  folder: string[];  // e.g. ['src', 'lua', 'modules']
  filename: string;  // e.g. 'file.lua'
}

function concatenateFiles(
  filesArray: FileDescriptor[],
  outputFileName: string
): void {
  try {
    const p = path.join(__dirname, '..')
    const buildDirPath = path.join(p, 'build');
    if (!fs.existsSync(buildDirPath)) {
      fs.mkdirSync(buildDirPath, { recursive: true });
    }

    const outputFilePath = path.join(buildDirPath, outputFileName);

    fs.writeFileSync(outputFilePath, '');
    fs.appendFileSync(outputFilePath, `-- ELARA ATC - build: ${process.env.npm_package_version}\n\n`)

    for (const fileDescriptor of filesArray) {
      const { folder, filename } = fileDescriptor;
      const filePath = path.join(p, ...folder, filename);
      const content = fs.readFileSync(filePath, 'utf8');

      fs.appendFileSync(outputFilePath, `\n\n-- ${filename}\n`)
      fs.appendFileSync(outputFilePath, content + '\n');
    }

    console.log(`Successfully concatenated files into: ${outputFilePath}`);
  } catch (error) {
    console.error('Error concatenating files:', error);
  }
}

// Example usage
const filesArray: FileDescriptor[] = [
  { folder: ['src', 'lua', 'modules'], filename: 'header.lua' },
  { folder: ['src', 'lua', 'modules'], filename: 'helpers.lua' },
  { folder: ['src', 'lua', 'modules'], filename: 'bool_settings.lua' },
  { folder: ['src', 'lua', 'modules'], filename: 'coolant.lua' },
  { folder: ['src', 'lua', 'modules'], filename: 'cycle.lua' },
  { folder: ['src', 'lua', 'modules'], filename: 'homing.lua' },
  { folder: ['src', 'lua', 'modules'], filename: 'magazine.lua' },
  { folder: ['src', 'lua', 'modules'], filename: 'register.lua' },
  { folder: ['src', 'lua', 'modules'], filename: 'tool_changer.lua' },
  { folder: ['src', 'lua', 'modules'], filename: 'tool_setter.lua' },

  { folder: ['src', 'lua', 'modules', 'elara_atc'], filename: 'elara_atc.lua' },

  { folder: ['src', 'lua', 'modules'], filename: 'end.lua' },
];

concatenateFiles(filesArray, `NS_CNC.lua`);