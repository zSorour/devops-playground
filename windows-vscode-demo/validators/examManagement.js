const { check } = require("express-validator");

module.exports.createExamValidator = () => [
  check("name").notEmpty().withMessage("ُExam name must not be empty."),
  check("duration").notEmpty().withMessage("Exam duration must not be empty."),
  check("duration").custom((value) => {
    if (value < 60) {
      throw new Error("Exam duration must be at least 60 minutes.");
    }
    return true;
  }),
  check("courseCode").notEmpty().withMessage("Course code must not be empty."),
  check("instructorID")
    .notEmpty()
    .withMessage("Instructor ID (createdBy) must not be empty."),
  check("instanceTemplateName")
    .notEmpty()
    .withMessage("Instance template must not be empty.")
];
