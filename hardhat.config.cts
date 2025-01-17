import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";

/*** begin typescript esm support snippet ***/
/** @see https://github.com/NomicFoundation/hardhat/issues/3385#issuecomment-1841380253 **/
import { join } from "node:path";
import { writeFile } from "node:fs/promises";
import { subtask } from "hardhat/config";
import { TASK_COMPILE_SOLIDITY } from "hardhat/builtin-tasks/task-names";

subtask(TASK_COMPILE_SOLIDITY).setAction(async (_, { config }, runSuper) => {
  const superRes = await runSuper();

  try {
    await writeFile(
      join(config.paths.artifacts, "package.json"),
      '{ "type": "commonjs" }'
    );
  } catch (error) {
    console.error("Error writing package.json: ", error);
  }

  return superRes;
});
/*** end typescript esm support snippet ***/

const config: HardhatUserConfig = {
  solidity: "0.8.28",
};

export default config;
